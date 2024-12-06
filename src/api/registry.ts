/* eslint-disable @typescript-eslint/require-await */
/* eslint-disable @typescript-eslint/no-unused-vars */

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
    protected server = "127.0.0.1",
    protected port = 10001
  ) {}

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
    server = "127.0.0.1",
    port = 10001
  ) {
    super(keyPair, server, port);
  }

  /**
   * Register a contract body
   * @param name name of the issuing body (e.g., "Univerisity of X")
   * @param domain domain of the issuing body (e.g., "xxx.edu")
   * @returns IssuingBody contract address
   */
  static async registerIssuingBody(
    keyPair: KeyPair,
    name: string,
    domain: string
  ): Promise<ContractAddress> {
    // TODO: Call Registry.registerIssuingBody
    return "381096eee6c43701c5f065cc0a7f29d5bedfcd6f";
  }

  /**
   * Create a new credential.
   * @param name name of the credential, e.g., Diploma
   * @param expiry UNIX timestamp offset of expiration time, 0 if non-expiring
   * @returns Credential ID of the new credential. See {@linkcode getCredById}.
   */
  async createCredential(name: string, expiry = 0): Promise<number> {
    // TODO: Call Registry.createCredential()
    return 0;
  }

  /**
   * Get all credentials registered under the issuing body.
   * @returns credentials associated with issuing body
   */
  async getCredAddrs(): Promise<ContractAddress[]> {
    // TODO: Call Registry.getCredentials()
    return [
      "1be8e78d765a2e63339fc99a66320db73158a35a",
      "b794caf2b323c4a5b92ee916fbbd82499ec620c5",
      "2087e41408c9f2095ba37bd461d80277d2f44197",
    ];
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
    return {
      name: "Bachelor of Science",
      address: "1be8e78d765a2e63339fc99a66320db73158a35a",
      issuingBodyAddr: this.address,
      id,
    };
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
    return {
      address: "e8c76cfb158ff8c624add0e1924c0fe706826894",
      publicKey: "e8c76cfb158ff8c624add0e1924c0fe706826894",
      privateKey: "e8c76cfb158ff8c624add0e1924c0fe706826894",
    };
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
    server = "127.0.0.1",
    port = 10001
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
  async getOwnerVerifyReqs(): Promise<CredentialOwnerVerifyRequest[]> {
    // TODO: Call Registry.getOwnerVerifyReqs() then call relevant property view functions
    return [
      {
        credGrantAddr: this.credGrant.address,
        verifier: "df7930b1d12e354cfc7f411d3f014eafcecc6b23",
        verifierName: "Example Inc",
        verifierDomain: "example.com",
      },
      {
        credGrantAddr: this.credGrant.address,
        verifier: "711da48058d5435dad701d5779a01cda592627e0",
        verifierName: "Foobar LLC",
        verifierDomain: "foobar.com",
      },
    ];
  }

  /**
   * Approve verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async approveVerifyReq(verifier: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.approveVerifyReq()
    return true;
  }

  /**
   * Reject verification request from given verifier address
   * @param verifier address of verifier
   * @returns true on success
   */
  async rejectVerifyReq(verifier: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.rejectVerifyReq()
    return true;
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
    server = "127.0.0.1",
    port = 10001
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
    return "6ce616d08abebfd40c1d3440c54f7686e696f92a";
  }

  /**
   * Send a verification request to a credential grant
   * @param credGrantAddr credential grant address
   * @returns true on success
   */
  async sendVerifyReq(credGrantAddr: ContractAddress): Promise<boolean> {
    // TODO: Call Registry.sendVerifyReq()
    return true;
  }

  /**
   * Get all past verification requests.
   * @returns list of a verification requests
   */
  async getVerifierVerifyReqs(): Promise<VerifierVerifyRequest[]> {
    // TODO: Call Registry.getVerifierVerifyReqs() then call necessary property view functions
    return [
      {
        verifier: this.keyPair.publicKey,
        reqId: 0,
        status: VerifyRequestStatus.Pending,
        credGrantAddr: "a3cf9f5a94362b6350ac92bcda78630051152bd8",
        granteeName: "Jane Doe",
        credentialName: "Bachelor of Science",
        issuingBodyName: "University of California, Davis",
      },
      {
        verifier: this.keyPair.publicKey,
        reqId: 1,
        status: VerifyRequestStatus.Approved,
        credGrantAddr: "a3cf9f5a94362b6350ac92bcda78630051152bd8",
        granteeName: "John Smith",
        credentialName: "Bachelor of Science",
        issuingBodyName: "University of California, Los Angeles",
      },
    ];
  }
}
