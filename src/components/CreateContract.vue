<template>
  <div class="container mt-5">
    <h1 class="text-center mb-5 title">Smart Contract Management</h1>

    <!-- Modal -->
    <div v-if="showModal" class="modal-b d-flex justify-content-center align-items-center">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Register Issuing Body</h5>
          </div>
          <div class="modal-body">
            <form @submit.prevent="handleRegisterIssuingBody">
              <div class="mb-3">
                <label for="issuingBodyName" class="form-label">Issuing Body Name</label>
                <input type="text" id="issuingBodyName" v-model="issuingBodyName" class="form-control"
                  placeholder="Enter issuing body name" required />
              </div>
              <div class="mb-3">
                <label for="issuingBodyDomain" class="form-label">Issuing Body Domain</label>
                <input type="text" id="issuingBodyDomain" v-model="issuingBodyDomain" class="form-control"
                  placeholder="Enter issuing body domain" required />
              </div>
              <button type="submit" class="btn btn-primary w-100">
                Register
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showCredModal" class="modal-b d-flex justify-content-center align-items-center">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Important</h5>
          </div>
          <div class="modal-body">
            <p>Send the following information to the recipient via a secure channel</p>

            <div class="mb-1">
              <div class="d-flex align-items-center">
                <label class="form-label me-2 mb-0 text-nowrap"><strong>Public Key:</strong></label>
                <p class="form-control-plaintext text-truncate mb-0" id="publicKey">{{ credModal?.publicKey }}</p>
                <button v-if="!publicKeyCopied" class="btn btn-outline-secondary btn-sm ms-2"
                  @click="copyToClipboard(credModal?.publicKey!, 'publicKeyCopied')">
                  Copy
                </button>
                <span v-if="publicKeyCopied" class="ms-2 text-success">Copied!</span>
              </div>
            </div>

            <div class="mb-1">
              <div class="d-flex align-items-center">
                <label class="form-label me-2 mb-0 text-nowrap"><strong>Private Key:</strong></label>
                <p class="form-control-plaintext text-truncate mb-0" :class="{ 'blurred': !showPrivateKey }"
                  id="privateKey">
                  {{ showPrivateKey ? credModal?.privateKey : '••••••••••••••••••••••••••••••••' }}
                </p>
                <button class="btn btn-outline-secondary btn-sm ms-2" @click="togglePrivateKeyVisibility">
                  {{ showPrivateKey ? 'Hide' : 'Show' }}
                </button>
                <button v-if="!privateKeyCopied" class="btn btn-outline-secondary btn-sm ms-2"
                  @click="copyToClipboard(credModal?.privateKey!, 'privateKeyCopied')">
                  Copy
                </button>
                <span v-if="privateKeyCopied" class="ms-2 text-success">Copied!</span>
              </div>
            </div>

            <div class="mb-2">
              <div class="d-flex align-items-center">
                <label class="form-label me-2 mb-0"><strong>Address:</strong></label>
                <p class="form-control-plaintext text-truncate mb-0" id="address">{{ credModal?.address }}</p>
                <button v-if="!addressCopied" class="btn btn-outline-secondary btn-sm ms-2"
                  @click="copyToClipboard(credModal?.address!, 'addressCopied')">
                  Copy
                </button>
                <span v-if="addressCopied" class="ms-2 text-success">Copied!</span>
              </div>
            </div>

            <div class="mb-3">
              <div class="d-flex align-items-center">
                <button v-if="!allCopied" class="btn btn-outline-secondary btn-sm"
                  @click="copyToClipboard(JSON.stringify(credModal), 'allCopied')">
                  Copy All
                </button>
                <span v-if="allCopied" class="text-success">Copied!</span>
              </div>
            </div>

            <form @submit.prevent="handleCredModalClose">
              <button type="submit" class="btn btn-primary w-100">
                Close
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>


    <div class="row">
      <div class="col-md-6 mb-4">
        <div class="card">
          <div class="card-header">Issue Credentials</div>
          <div class="card-body">
            <form @submit.prevent="grantCredentials">
              <div class="mb-3">
                <label for="credentialName" class="form-label">Credential Name</label>
                <select id="credentialName" v-model="credential" class="form-select" required>
                  <option value="" disabled>Select a credential</option>
                  <option v-for="cred in ownedCreds" :key="cred.id" :value="cred">
                    {{ cred.name }}
                  </option>
                </select>
              </div>

              <div class="mb-3">
                <label for="recipient" class="form-label">Recipient</label>
                <input type="text" id="recipient" v-model="recipient" class="form-control" placeholder="Enter recipient"
                  required />
              </div>

              <div class="mb-3">
                <label for="expiration" class="form-label">Expiration</label>
                <input type="text" id="expiration" v-model="expiration" class="form-control"
                  placeholder="Expiration Time" required />
              </div>

              <button type="submit" class="btn btn-success w-100">
                Issue Credential
              </button>
            </form>
          </div>
        </div>
      </div>

      <div class="col-md-6 mb-4">
        <div class="card">
          <div class="card-header">Create Credential Type</div>
          <div class="card-body">
            <form @submit.prevent="createCredentialType">
              <div class="mb-3">
                <label for="typeName" class="form-label">Credential Type Name</label>
                <input type="text" id="credentialType" v-model="credentialType" class="form-control"
                  placeholder="Enter credential type name" required />
              </div>
              <button type="submit" class="btn btn-info w-100">
                Create Type
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <!-- Issued Credentials -->
      <div class="col-md-6 mb-4">
        <div class="card" style="max-height: 400px; overflow-y: auto;">
          <div class="card-header">Issued Credentials</div>
          <div class="card-body">
            <ul class="list-group">
              <li class="list-group-item" v-for="cred in credentialGrantees" :key="cred.address">
                <div class="d-flex justify-content-between align-items-center">
                  <h6 class="mb-0">{{ cred.granteeName }}</h6>
                  <span class="text-muted small truncate-text">{{ cred.address.substring(2).replace(/^0+/, '') }}</span>
                </div>
                <div class="mt-2">
                  <p class="mb-1 truncate-text"><strong>Credential Address:</strong> {{
                    cred.credentialAddr.substring(2).replace(/^0+/, '') }}</p>
                  <p class="mb-1"><strong>Credential Name:</strong> {{ cred.name }}</p>
                  <p class="mb-0"><strong>Expiry:</strong> {{ cred.expiry }}</p>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Credential Types -->
      <div class="col-md-6 mb-4">
        <div class="card" style="max-height: 400px; overflow-y: auto;">
          <div class="card-header">Credential Types</div>
          <div class="card-body">
            <ul class="list-group">
              <li class="list-group-item" v-for="cred in ownedCreds" :key="cred.id">
                <div class="d-flex justify-content-between align-items-center">
                  <h6 class="mb-0 me-3">{{ cred.name }}</h6>
                  <span class="text-muted small truncate-text ms-auto">{{ cred.address.substring(2).replace(/^0+/, '')
                    }}</span>
                </div>
                <div class="mt-2">
                  <p class="mb-1 truncate-text"><strong>Issuing Body Address:</strong> {{
                    cred.issuingBodyAddr.substring(2).replace(/^0+/, '') }}</p>
                  <p class="mb-0"><strong>Id:</strong> {{ cred.id }}</p>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, onMounted, ref } from "vue";
import { type Credential, IssuingBodyClient, type KeyPair } from "../api/registry";

export default defineComponent({
  name: "CreateContract",
  setup() {
    type CredGrant = {
      granteeName: string;
      expiry: number;
      address: string;
      credentialAddr: string;
      name: string;
    }

    type CredModal = {
      address: string,
      publicKey: string,
      privateKey: string,
    };

    const issuingBody = ref<IssuingBodyClient>();
    const ownedCreds = ref<Credential[]>([]);
    const credentialGrantees = ref<CredGrant[]>([]);

    const issuingBodyName = ref<string>("");
    const issuingBodyDomain = ref<string>("");
    const showModal = ref<boolean>(true);

    const credential = ref<Credential>();
    const recipient = ref<string>("");

    const expiration = ref<number>();

    const credentialType = ref<string>();

    const showCredModal = ref<boolean>(false);
    const credModal = ref<CredModal>();

    const showPrivateKey = ref<boolean>(false);

    const publicKeyCopied = ref<boolean>(false);
    const privateKeyCopied = ref<boolean>(false);
    const addressCopied = ref<boolean>(false);

    const allCopied = ref<boolean>(false);

    onMounted(async () => {
      const kp = localStorage.getItem("keyPair");
      if (!kp) return;
      const keyPair = JSON.parse(kp);

      const issBody = getIssuingBody(keyPair);

      if (issBody) {
        showModal.value = false;
        issuingBodyName.value = JSON.parse(issBody).name;
        issuingBodyDomain.value = JSON.parse(issBody).domain;
        handleRegisterIssuingBody();
      }
    })

    const handleRegisterIssuingBody = async () => {
      if (!issuingBodyName.value || !issuingBodyDomain.value) {
        alert("Both fields are required.");
        return;
      }

      const keyPair = await getKeyPair();
      let issuingBodyAddr = getIssuingBody(keyPair);

      if (!issuingBodyAddr) {
        issuingBodyAddr = await IssuingBodyClient.registerIssuingBody(
          issuingBodyName.value,
          issuingBodyDomain.value,
          keyPair,
        );
        localStorage.setItem(`${keyPair.publicKey}_${keyPair.privateKey}`, JSON.stringify({ addr: issuingBodyAddr, name: issuingBodyName.value, domain: issuingBodyDomain.value }));
      } else {
        issuingBodyAddr = JSON.parse(issuingBodyAddr).addr;
        if (!issuingBodyAddr) return;
      }

      issuingBody.value = new IssuingBodyClient(keyPair, issuingBodyAddr);

      showModal.value = false;

      ownedCreds.value = await getAllCreds(issuingBody.value);
      credentialGrantees.value = await getAllGrantees(issuingBody.value, ownedCreds.value);
    };

    const getIssuingBody = (keyPair: KeyPair): string | null => {
      const issuingBodyAddr = localStorage.getItem(`${keyPair.publicKey}_${keyPair.privateKey}`);
      return issuingBodyAddr || null;
    };

    const getAllGrantees = async (issuingBody: IssuingBodyClient, credentials: Credential[]): Promise<CredGrant[]> => {
      const grantees: CredGrant[] = [];

      for (const cred of credentials) {
        const grants = await issuingBody.getCredGrants(cred.address);

        for (let i = 0; i < grants.length; i++) {
          const name = ownedCreds.value.find((val) => val.address === grants[i].credentialAddr);
          if (!name?.name) continue;
          const newGrant = { ...grants[i], name: name?.name }
          grantees.push(newGrant);
        }
      }

      return grantees;
    };

    const getAllCreds = async (issuingBody: IssuingBodyClient): Promise<Credential[]> => {
      const allAddrs = await issuingBody.getCredAddrs();
      const allCreds: Array<Credential> = [];

      for (let i = 0; i < allAddrs.length; i++) {
        const cred = await issuingBody.getCredById(i);
        allCreds.push(cred);
      }

      return allCreds;
    };

    const getKeyPair = async (): Promise<KeyPair> => {
      const stored = localStorage.getItem("keyPair");
      let keyPair: KeyPair = { privateKey: "", publicKey: "" };

      if (!stored) {
        keyPair = await IssuingBodyClient.generateKeyPair();
        const stringified = JSON.stringify({
          publicKey: keyPair.publicKey,
          privateKey: keyPair.privateKey,
        });
        localStorage.setItem("keyPair", stringified);
      } else {
        keyPair = JSON.parse(stored);
      }

      return keyPair;
    };

    const grantCredentials = async () => {
      if (!credential.value?.name || !expiration.value) return;

      const newCred = await issuingBody.value?.grantCredential(credential.value.address, recipient.value, expiration.value);
      if (!newCred?.address) return;

      credentialGrantees.value.push({ name: credential.value.name, granteeName: recipient.value, address: newCred?.address, credentialAddr: credential.value.address, expiry: expiration.value });

      const keyPair = await getKeyPair();
      credModal.value = { address: newCred?.address, publicKey: keyPair.publicKey, privateKey: keyPair.privateKey };
      showCredModal.value = true;

      expiration.value = undefined;
      recipient.value = "";
      credential.value = { name: "", address: "", issuingBodyAddr: "", id: -1 };
    };

    const handleCredModalClose = () => {
      credModal.value = { address: "", publicKey: "", privateKey: "" };
      showCredModal.value = false;
    }

    const togglePrivateKeyVisibility = () => {
      showPrivateKey.value = !showPrivateKey.value;
    };

    const copyToClipboard = (value: string, key: string) => {
      navigator.clipboard.writeText(value).then(() => {
        if (key === 'publicKeyCopied') publicKeyCopied.value = true;
        if (key === 'privateKeyCopied') privateKeyCopied.value = true;
        if (key === 'addressCopied') addressCopied.value = true;
        if (key === 'allCopied') allCopied.value = true;

        setTimeout(() => {
          if (key === 'publicKeyCopied') publicKeyCopied.value = false;
          if (key === 'privateKeyCopied') privateKeyCopied.value = false;
          if (key === 'addressCopied') addressCopied.value = false;
          if (key === 'allCopied') allCopied.value = false;
        }, 1000);
      });
    };

    const createCredentialType = async () => {
      if (!credentialType.value || !issuingBody.value?.address) return;

      const credId = await issuingBody.value?.createCredential(credentialType.value);

      const credAddress = await issuingBody.value.getCredById(credId);

      ownedCreds.value.push({ name: credentialType.value, issuingBodyAddr: issuingBody.value?.address, id: credId, address: credAddress.address });

      credentialType.value = "";
    };

    return {
      issuingBody,
      ownedCreds,
      credentialGrantees,
      issuingBodyName,
      issuingBodyDomain,
      showModal,
      credential,
      recipient,
      expiration,
      credentialType,
      showCredModal,
      credModal,
      showPrivateKey,
      publicKeyCopied,
      privateKeyCopied,
      addressCopied,
      allCopied,
      handleRegisterIssuingBody,
      grantCredentials,
      createCredentialType,
      handleCredModalClose,
      copyToClipboard,
      togglePrivateKeyVisibility
    };
  },
});

</script>

<style scoped>
.modal-b {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 1050;
}

.modal-dialog {
  background: white;
  border-radius: 8px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
  max-width: 500px;
  width: 90%;
  padding: 1rem;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #dee2e6;
  padding-bottom: 0.5rem;
}

.modal-body {
  padding-top: 1rem;
}

.title {
  color: white;
}

.truncate-text {
  display: inline-block;
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.blurred {
  filter: blur(6px);
  user-select: none;
  cursor: pointer;
}
</style>
