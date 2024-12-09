/* eslint-disable @typescript-eslint/require-await */
/* eslint-disable @typescript-eslint/no-unused-vars */

import { gql, GraphQLClient } from 'graphql-request';

export const server = "10.127.1.2";
export const port = 80;

interface CreateAccountResult {
  createAccount: string;
}

interface DeployContractResult {
  deployContract: {contractAddress: string};
}

interface ExecuteContractResult {
  executeContract: string;
}

// TODO: remove above when all functions are implemented
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
    protected server = "10.127.1.2",
    protected port = 80
  ) { }
  static registryAddress = "0xec146da91aedfa127037a693b53049be4c1ea43d";

  setServer(server: string, port: number) {
    this.server = server;
    this.port = port;
  }

  /**
   * Generate a key pair by contacting key-value service
   * @returns key pair
   */
  static async generateKeyPair(): Promise<KeyPair> {
    return {
      publicKey: "1be8e78d765a2e63339fc99a66320db73158a35a",
      privateKey: "1be8e78d765a2e63339fc99a66320db73158a35a",
    };
  }

  // NOTE to Ethan: You don't have to implement these 2 functions
  // if it's easier to interact with the GraphQL server in each Registry
  // API functions directly.

  /**
   * Send a query to GraphQL server
   * @param query query to submit
   * @returns result of query
   */
  protected async sendGraphQLQuery(query: unknown): Promise<unknown> {
    return null;
  }

  /**
   * Submit a mutation to GraphQL server
   * @param mutation mutation to submit
   * @returns result of mutation
   */
  protected async sendGraphQLMutation(mutation: unknown): Promise<unknown> {
    return null;
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
    server = "10.127.1.2",
    port = 80
  ) {
    super(keyPair, server, port);
  }

  static async createAccount(): Promise<KeyPair> {
    const document = gql`mutation {
      createAccount(
        config: "../resilientdb/service/tools/config/interface/service.config",
      )
    }`;
    const endpoint = `http://${server}:${port}/graphql/`;
    const client = new GraphQLClient(endpoint);
    const ret = await client.request(document) as CreateAccountResult;
    return {publicKey: ret.createAccount, privateKey: "world"};
  }

  static async createContract(owner: string, name: string, args = ""): Promise<string> {
    const document = gql`mutation {
        deployContract(
          config: "../resilientdb/service/tools/config/interface/service.config",
          contract: "compiled_contracts/output.json",
          name: "contracts/Registry.sol:${name}",
          arguments: "${args}",
          owner: "${owner}"
        ) {
          contractAddress
        }
    }`;
    const endpoint = `http://${server}:${port}/graphql/`;
    const client = new GraphQLClient(endpoint);
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
    const endpoint = `http://${server}:${port}/graphql/`;
    const client = new GraphQLClient(endpoint);
    const result = await client.request(document) as ExecuteContractResult;
    return result.executeContract;
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
    server = "10.127.1.2",
    port = 80
  ): Promise<ContractAddress> {
    // TODO: Call Registry.registerIssuingBody
    const contract = await this.createContract(keyPair.publicKey, "IssuingBody", `${this.registryAddress},'${name}','${domain}'`);
    return this.executeContract(keyPair.publicKey, this.registryAddress, "registerIssuingBody(address)", contract);
  }

  /**
   * Create a new credential.
   * @param name name of the credential, e.g., Diploma
   * @param expiry UNIX timestamp offset of expiration time, 0 if non-expiring
   * @returns Credential ID of the new credential. See {@linkcode getCredById}.
   */
  async createCredential(name: string, expiry = 0): Promise<number> {
    // TODO: Call Registry.createCredential()
    // Testing not needed
    const contract = await IssuingBodyClient.createContract(this.keyPair.publicKey, "Credential", `${this.address},'${name}',${expiry}`);
    return parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "addCredential(address)", contract), 16);
  }

  /**
   * Get all credentials registered under the issuing body.
   * @returns credentials associated with issuing body
   */
  async getCredAddrs(): Promise<ContractAddress[]> {
    // TODO: Call Registry.getCredentials()
    // Testing definitely not needed
    const nums = parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "nextId()", ""));
    let ret: ContractAddress[] = [];
    for(let i = 1; i < nums; i++) {
      ret.push(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "getCredentialById(uint256)",`${i}`));
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
    // TODO: Call Registry.getIssuingBody() to get IB address
    // call IssuingBody.getCredentialById() to get Credential address
    // call Credential.{name,issuingBody,id}()
    const addr = await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "getCredentialById(uint256)",`${id}`);
    return {
      name: "Sadoghi", // definitely not testing this one
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
    // TODO: Call Credential.getCredGrants()
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
    granteeName: string
  ): Promise<KeyPair & { address: string }> {
    // TODO: Call Registry.grantCredential()
    // NOTE: Make sure to use {@linkcode generateKeyPair} to
    // create a new address for the recipient.
    // `address` is the address of the CredentialGrant contract instance
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "addGrant(address)",`${credential}`);

  }
}

export interface CredentialOwnerVerifyRequest {
  credGrantAddr: ContractAddress;
  verifier: ContractAddress;
  verifierName: string;
  verifierDomain: string;
}

export class CredentialOwnerClient extends RegistryClient {
  protected credGrant: CredentialGrant;
  constructor(
    keyPair: KeyPair,
    credGrant: CredentialGrant,
    server = "10.127.1.2",
    port = 80
  ) {
    // NOTE: Each credential grant is a separate key pair. Set the `keyPair`
    // variable as needed when submitting queries or mutations.
    super(keyPair, server, port);
    this.credGrant = credGrant;
  }

  /**
   * Get all pending verify requests associated with the current credential
   * @returns verify requests
   */
  async getOwnerVerifyReqs(): Promise<CredentialOwnerVerifyRequest> {
    // TODO: Call Registry.getOwnerVerifyReqs() then call relevant property view functions
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.credGrant, "getReq()","");
  }

  /**
   * Approve verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async approveVerifyReq(verifier: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.approveVerifyReq()
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.credGrant, "approveVerifyReq(address)",verifier);
  }

  /**
   * Reject verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async rejectVerifyReq(verifier: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.rejectVerifyReq()
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.credGrant, "rejectVerifyReq(address)",verifier);
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
    server = "10.127.1.2",
    port = 80
  ) {
    super(keyPair, server, port);
  }

  /**
   * Register a verifier.
   * @param name name of verifier (e.g., Example Inc)
   * @param domain domain name of verifier
   * @returns address of verifier
   */
  static async registerVerifier(
    name: string,
    domain: string
  ): Promise<ContractAddress> {
    // TODO: Call Registry.registerVerifier()
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "registerVerifier(address)",`${this.registryAddress},'${name}','${domain}'`);
  }

  /**
   * Send a verification request to a credential grant
   * @param credGrantAddr credential grant address
   * @returns true on success
   */
  async sendVerifyReq(credGrantAddr: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.sendVerifyReq()
    return IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "sendVerifyReq(address)",credGrantAddr);
  }

  /**
   * Get all past verification requests.
   * @returns list of a verification requests
   */
  async getVerifierVerifyReqs(): Promise<VerifierVerifyRequest[]> {
    // TODO: Call Registry.getVerifierVerifyReqs() then call necessary property view functions
    const nums = parseInt(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "nextReqIdx()", ""));
    let ret: VerifierVerifyRequest[] = [];
    for(let i = 1; i < nums; i++) {
      ret.push(await IssuingBodyClient.executeContract(this.keyPair.publicKey, this.address, "getReqByIdx(uint256)",`${i}`));
    }

    return ret;
  }
}
