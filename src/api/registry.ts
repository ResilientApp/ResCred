import { gql, GraphQLClient } from 'graphql-request';

export const SERVER = "10.127.1.2";
export const PORT = 80;
export const ENDPOINT = `http://${SERVER}:${PORT}/graphql/`;

interface CreateAccountResult {
  createAccount: string;
}

interface DeployContractResult {
  deployContract: { contractAddress: string };
}

interface ExecuteContractResult {
  executeContract: string;
}

export interface KeyPair {
  publicKey: string;
  privateKey: string;
}

export type Address = string;
export type ContractAddress = string;

export interface Credential {
  name: string;
  address: ContractAddress;
  issuingBodyAddr: ContractAddress;
  id: number;
}

export interface CredentialGrant {
  granteeName: string;
  expiry: number; // UNIX timestamp
  address: ContractAddress;
  credentialAddr: ContractAddress;
}

export class RegistryClient {
  constructor(
    protected keyPair: KeyPair,
  ) { }
  static REGISTRY_ADDR = "0xec146da91aedfa127037a693b53049be4c1ea43d";

  /**
   * Generate a key pair by contacting key-value service
   * @returns key pair
   */
  static async generateKeyPair(): Promise<KeyPair> {
    return this.createAccount();
  }

  static async createAccount(): Promise<KeyPair> {
    const document = gql`mutation {
      createAccount(
        config: "../resilientdb/service/tools/config/interface/service.config",
      )
    }`;
    const client = new GraphQLClient(ENDPOINT);
    const ret = await client.request(document) as CreateAccountResult;
    return { publicKey: ret.createAccount, privateKey: "world" };
  }

  static async deployContract(owner: string, name: string, args = ""): Promise<string> {
    const document = gql`mutation {
        deployContract(
          config: "../resilientdb/service/tools/config/interface/service.config",
          contract: "compiled_contracts/output.json",
          name: "ecs189f/contracts/Registry.sol:${name}",
          arguments: "${args}",
          owner: "${owner}"
        ) {
          contractAddress
        }
    }`;
    const client = new GraphQLClient(ENDPOINT);
    const ret = await client.request(document) as DeployContractResult;
    console.log(ret);
    return ret.deployContract.contractAddress;
  }

  static async executeContract(sender: string, contract: string, funcName: string, args: string): Promise<string> {
    const document = gql`mutation {
        executeContract(
          config: "../resilientdb/service/tools/config/interface/service.config",
          sender: "${sender}",
          contract: "${contract}",
          functionName: "${funcName}",
          arguments: "${args}",
        )}`;
    const client = new GraphQLClient(ENDPOINT);
    const result = await client.request(document) as ExecuteContractResult;
    return result.executeContract;
  }
}

/**
 * For a new user, create a keypair using {@linkcode generateKeyPair} and
 * register the issuing body using {@linkcode registerIssuingBody}
 * before instantiating the client.
 */
export class IssuingBodyClient extends RegistryClient {
  constructor(
    keyPair: KeyPair,
    readonly address: ContractAddress, // contract address of the IssuingBody
  ) {
    super(keyPair);
  }

  /**
   * Register a contract body
   * @param name name of the issuing body (e.g., "Univerisity of X")
   * @param domain domain of the issuing body (e.g., "xxx.edu")
   * @returns IssuingBody contract address
   */
  static async registerIssuingBody(
    name: string,
    domain: string,
    keyPair: KeyPair,
  ): Promise<ContractAddress> {
    const contract = await this.deployContract(keyPair.publicKey, "IssuingBody", `${this.REGISTRY_ADDR},'${name}','${domain}'`);
    return this.executeContract(keyPair.publicKey, this.REGISTRY_ADDR, "registerIssuingBody(address)", contract);
  }

  /**
   * Create a new credential.
   * @param name name of the credential, e.g., Diploma
   * @param expiry UNIX timestamp offset of expiration time, 0 if non-expiring
   * @returns Credential ID of the new credential. See {@linkcode getCredById}.
   */
  async createCredential(name: string, expiry = 0): Promise<number> {
    const contract = await IssuingBodyClient.deployContract(this.keyPair.publicKey, "Credential", `${this.address},'${name}',${expiry}`);
    return parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "addCredential(address)", contract), 16);
  }

  /**
   * Get all credentials registered under the issuing body.
   * @returns credentials associated with issuing body
   */
  async getCredAddrs(): Promise<ContractAddress[]> {
    const nums = parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "nextId()", ""));
    let ret: ContractAddress[] = [];
    for (let i = 1; i < nums; i++) {
      ret.push(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "getCredentialById(uint256)", `${i}`));
    }

    return ret;
  }

  /**
   * Get credential by ID (ID is local to this issuing body)
   * @param issuingBodyAddr
   * @param id
   * @returns
   */
  async getCredById(id: number): Promise<Credential> {
    const addr = await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "getCredentialById(uint256)", `${id}`);
    return {
      name: "Masters of Science",
      address: addr,
      issuingBodyAddr: this.address,
      id: id,
    }
  }

  /**
   * Get all credential grants (i.e., basically all grantees)
   * @param credentialAddr address of the credential
   * @returns all credential grants
   */
  async getCredGrants(
    credentialAddr: ContractAddress
  ): Promise<CredentialGrant[]> {
    return [
      {
        granteeName: "Jane Doe",
        address: "e8c76cfb158ff8c624add0e1924c0fe706826894",
        credentialAddr,
        expiry: 0, // never expire
      },
      {
        granteeName: "John Smith",
        address: "c1d9f669d577486e3352d7e1253aacb672392fb3",
        credentialAddr,
        expiry: 1746496086,
      },
    ];
  }

  /**
   * Grant a credential to an address.
   * @param credential address of credential
   * @param grantee grantee address
   * @returns key pair of the new credential
   */
  async grantCredential(
    credential: ContractAddress,
    granteeName: string,
    expiry = 0
  ): Promise<KeyPair & { address: string }> {
    const acct = await RegistryClient.createAccount();
    const grant = await RegistryClient.deployContract(this.keyPair.publicKey, "CredentialGrant", `${credential},${acct.publicKey},'${granteeName}',${expiry}`)
    await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "addGrant(address)", `${grant}`);
    return {
      address: grant,
      ...acct
    }
  }
}

export interface CredentialOwnerVerifyRequest {
  credGrantAddr: ContractAddress;
  verifier: ContractAddress;
  verifierName: string;
  verifierDomain: string;
}

export class CredentialOwnerClient extends RegistryClient {
  protected credGrant: ContractAddress;
  constructor(
    keyPair: KeyPair,
    credGrant: ContractAddress,
  ) {
    // NOTE: Each credential grant is a separate key pair. Set the `keyPair`
    // variable as needed when submitting queries or mutations.
    super(keyPair);
    this.credGrant = credGrant;
  }

  /**
   * Get all pending verify requests associated with the current credential
   * @returns verify requests
   */
  async getOwnerVerifyReqs(): Promise<CredentialOwnerVerifyRequest> {
    /**
     * 
export interface CredentialOwnerVerifyRequest {
  credGrantAddr: ContractAddress;
  verifier: ContractAddress;
  verifierName: string;
  verifierDomain: string;
}
     */
    const reqId = await RegistryClient.executeContract(this.keyPair.publicKey, this.credGrant, "getReq()", "");
    const reqAddr = await RegistryClient.executeContract(this.keyPair.publicKey, RegistryClient.REGISTRY_ADDR, "getOwnerVerifyReqById(uint256)", reqId);
    const verifier = await RegistryClient.executeContract(this.keyPair.publicKey, reqAddr, "verifier()", "");
    return {
      credGrantAddr: this.credGrant,
      verifier,
      verifierName: "Example Inc",
      verifierDomain: "example.com"
    }
  }

  /**
   * Approve verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async approveVerifyReq(reqId: number): Promise<boolean> {
    const result = await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.credGrant, "approveVerifyReq(uint256)", `${reqId}`);
    return parseInt(result, 16) == 1;
  }

  /**
   * Reject verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async rejectVerifyReq(reqId: number): Promise<boolean> {
    const result = await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.credGrant, "rejectVerifyReq(address)", `${reqId}`);
    return parseInt(result, 16) == 1;
  }
}

enum VerifyRequestStatus {
  Pending = 0,
  Approved = 1,
  Rejected = 2,
}

interface VerifierVerifyRequest {
  verifier: ContractAddress;
  status: VerifyRequestStatus;
  reqId: number;
  credGrantAddr: ContractAddress;
  granteeName: string;
  credentialName: string;
  issuingBodyName: string;
}

/**
 * For a new user, create a keypair using {@linkcode generateKeyPair} and register a
 * verifier using {@linkcode registerVerifier} before instantiating the client.
 */
export class VerifierClient extends RegistryClient {
  constructor(
    keyPair: KeyPair,
    readonly address: ContractAddress,
  ) {
    super(keyPair);
  }

  /**
   * Register a verifier.
   * @param name name of verifier (e.g., Example Inc)
   * @param domain domain name of verifier
   * @returns address of verifier
   */
  static async registerVerifier(
    keyPair: KeyPair,
    name: string,
    domain: string
  ): Promise<ContractAddress> {
    return RegistryClient.executeContract(keyPair.publicKey, RegistryClient.REGISTRY_ADDR, "registerVerifier(address)", `${this.REGISTRY_ADDR},'${name}','${domain}'`);
  }

  /**
   * Send a verification request to a credential grant
   * @param credGrantAddr credential grant address
   * @returns true on success
   */
  async sendVerifyReq(credGrantAddr: ContractAddress): Promise<boolean> {
    const result = await RegistryClient.executeContract(this.keyPair.publicKey, this.address, "sendVerifyReq(address)", credGrantAddr);
    return parseInt(result, 16) == 1;
  }

  /**
   * Get all past verification requests.
   * @returns list of a verification requests
   */
  async getVerifierVerifyReqs(): Promise<VerifierVerifyRequest[]> {
    const nums = parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "nextReqIdx()", ""));
    let ret: VerifierVerifyRequest[] = [];
    for (let i = 1; i < nums; i++) {
      const reqAddr = await RegistryClient.executeContract(this.keyPair.publicKey, this.address, "getReqByIdx(uint256)", `${i}`);
      const grantAddr = await RegistryClient.executeContract(this.keyPair.publicKey, reqAddr, "credGrant()", "");
      const status = await RegistryClient.executeContract(this.keyPair.publicKey, reqAddr, "status()", "");
      const statusMsg = {
        0: VerifyRequestStatus.Pending,
        1: VerifyRequestStatus.Approved,
        2: VerifyRequestStatus.Rejected
      }[parseInt(status, 16)] || VerifyRequestStatus.Pending;
      ret.push({
        verifier: this.address,
        credentialName: "Master of Science",
        credGrantAddr: grantAddr,
        granteeName: "John Smith",
        issuingBodyName: "Example University",
        reqId: i,
        status: statusMsg
      });
    }
    return ret;
  }
}
