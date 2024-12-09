<template>
  <div class="page-container">
    <div class="form-container">
      <h1 class="heading"> Credentials</h1>
      <!-- beggining of Modal for week 2-->
      <b-modal v-model="showImportModal" title="Import Credential" dialog-class="custom-modal" hide-footer>
        <b-form @submit.prevent="handleImport">
          <b-form-group label="Credential Data">
            <b-form-textarea v-model="importedCredential" required></b-form-textarea>
          </b-form-group>
          <b-button type="submit" variant="success">Import</b-button>

        </b-form>
      </b-modal>



      <!-- END of Modal for week 2-->
      <b-container>
        <section class="credential-section">
          <div class="button-group">
            <b-button variant="primary" class="button" @click="refreshReq()"
              v-if="credential != null">Refresh</b-button>
            <b-button variant="primary" class="button" @click="showImportModal = true"
              v-if="credential == null || true">
              Import Credential
            </b-button>
          </div>
          <!-- Pending Section -->
          <section class="credential-section" v-if="pendingReq != null">
            <b-card class="mb-3" header="Verification Request">
              <p><strong>ID:</strong> {{ pendingReq.id }}</p>
              <p><strong>Credential Address:</strong> {{ pendingReq.credGrantAddr }}</p>
              <p><strong>Verifier Name:</strong> {{ pendingReq.verifierName }}</p>
              <p><strong>Verifier Domain:</strong> {{ pendingReq.verifierDomain }}</p>
              <b-button variant="success" @click="approveReq()">Approve</b-button>
              <b-button variant="danger" @click="rejectReq()">Reject</b-button>
            </b-card>
          </section>
        </section>
        <section class="credential-section" v-if="credential != null">
          <!-- Approved Section -->
          <transition-group name="credential-card" tag="div" class="b-row">
            <CredentialCard :credential="credential" />
          </transition-group>
        </section>
        <!-- Confirmation Modal -->
        <ConfirmationModal v-model:isVisible="isModalVisible" :title="modalTitle" :message="modalMessage"
          :actionType="actionType" :Credential="selectedCredential" @confirm="handleConfirm" />
      </b-container>
    </div>
  </div>
</template>


<script lang="ts">
import { defineComponent, ref } from 'vue';
import { CredentialGrant, CredentialGrantData, CredentialOwnerClient, CredentialOwnerVerifyRequest, RegistryClient } from '../api/registry';
import ConfirmationModal from './ConfirmationModal.vue';
import CredentialCard from './CredentialCard.vue';

export default defineComponent({
  name: 'CredentialHolderDashboard',
  components: { CredentialCard, ConfirmationModal },
  setup() {
    const client = ref<CredentialOwnerClient | null>(null);
    const credential = ref<CredentialGrant | null>(null);
    const pendingReq = ref<CredentialOwnerVerifyRequest | null>(null);
    const credString = localStorage.getItem("cred");
    if (credString != null) {
      const cred = JSON.parse(credString) as CredentialGrantData;
      client.value = new CredentialOwnerClient(cred, cred.address);
      const credentialAddr = localStorage.getItem("credAddr") || ""
      const expiry = parseInt(localStorage.getItem("expiry") || "0");
      credential.value = { address: cred.address, credentialAddr, expiry, granteeName: "John Smith" };
    }

    const refreshReq = async () => {
      if (client.value == null) {
        return;
      }
      pendingReq.value = await client.value.getVerifyReq();
    }

    const handleImport = async () => {
      if (importedCredential.value.length == 0) {
        alert('Please fill in all fields.');
        return;
      }
      showImportModal.value = false;
      localStorage.setItem("cred", importedCredential.value)
      const cred = JSON.parse(importedCredential.value) as CredentialGrantData;
      client.value = new CredentialOwnerClient(cred, cred.address);
      const credAddr = await RegistryClient.executeContract(cred.publicKey, cred.address, "credential()", "");
      const expiry = await RegistryClient.executeContract(cred.publicKey, cred.address, "expiry()", "");
      localStorage.setItem("credAddr", credAddr)
      const expiryNum = parseInt(expiry, 16);
      localStorage.setItem("expiry", `${expiryNum}`)
      credential.value = { address: cred.address, credentialAddr: credAddr, expiry: expiryNum, granteeName: "John Smith" };
      importedCredential.value = "";
    };

    const approveReq = async () => {
      try {
        // Simulate using a backend function to approve the credential
        if (client.value == null) {
          alert("Please import credential first!");
          return;
        }
        if (pendingReq.value == null) {
          alert("No request available");
          return;
        }
        const result = await client.value.rejectVerifyReq(pendingReq.value.id);
        if (result) {
          alert('Credential rejected successfully.');
          pendingReq.value = null;
        } else {
          alert('Credential approval failed');
        }
      } catch (error) {
        console.error('Error approving credential:', error);
        alert('An error occurred while approving the credential.');
      }
    };

    const rejectReq = async () => {
      try {
        if (client.value == null) {
          alert("Please import credential first!");
          return;
        }

        if (pendingReq.value == null) {
          alert("No request available");
          return;
        }
        const result = await client.value.rejectVerifyReq(pendingReq.value.id);
        if (result) {
          alert('Credential rejected successfully.');
          pendingReq.value = null;
        } else {
          alert('Credential rejection failed');
        }
      } catch (error) {
        console.error('Error rejecting credential:', error);
        alert('An error occurred while rejecting the credential.');
      }
    };

    const handleConfirm = () => {
      // Close the confirmation modal
      if (confirmationModal.value) {
        confirmationModal.value.isVisible = false;
      }
    };


    type Credential = {
      id: number;
      name: string;
      holder: string;
      issuer: string;
      domain: string;
      status: string;
    };

    const showImportModal = ref(false);
    const importedCredential = ref<string>("");
    const modalTitle = ref('');
    const modalMessage = ref('');
    const selectedCredential = ref<Credential | null>(null);
    const actionType = ref('');
    const isModalVisible = ref(false);
    const confirmationModal = ref<{ isVisible: boolean } | null>(null);

    const openConfirmModal = (action: string, credential: any) => {
      ref(null); // Reference to modal
      console.log('Event Triggered:', action, credential); // Debug Log
      modalTitle.value = action === 'approve' ? 'Approve Credential' : 'Reject Credential';
      modalMessage.value = `Are you sure you want to ${action} the credential "${credential.name}"?`;
      actionType.value = action;
      selectedCredential.value = credential;
      isModalVisible.value = true;
      console.log('Modal Visibility:', isModalVisible.value); // Debug Log
    };

    return {
      // credentials,
      client,
      credential,
      modalTitle,
      modalMessage,
      openConfirmModal,
      handleConfirm,
      confirmationModal, // Return modal reference
      refreshReq,
      pendingReq,
      // approvedCredentials, // Return computed property
      // pendingCredentials,
      isModalVisible,
      approveReq,
      actionType,
      rejectReq,
      selectedCredential,
      showImportModal,
      importedCredential,
      handleImport,
    };
  },
});
</script>

<style scoped>
.custom-container {
  max-width: 100%;
  /* Override Bootstrap's default max-width */
  width: 100%;
}


/* Style for the credentials container */
.credentials-section {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  /* Spacing between boxes */
  justify-content: center;
  margin-top: 20px;
}

/* Base style for credential boxes */
.credential-box {
  width: 200px;
  /* Set a fixed width for square-like shape */
  height: 200px;
  /* Set equal height for a square */
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  padding: 10px;
  color: white;
  /* White text */
  font-size: 1rem;
  text-align: center;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
  /* Subtle shadow */
  border: 2px solid rgba(255, 255, 255, 0.2);
}

/* Pending box with blue transparency */
.pending {
  background-color: rgba(59, 130, 246, 0.2);
  /* Blue transparency */
  border-left: 5px solid #3b82f6;
  /* Left border for distinction */
}

/* Approved box with green transparency */
.approved {
  background-color: rgba(16, 185, 129, 0.2);
  /* Green transparency */
  border-left: 5px solid #10b981;
  /* Left border for distinction */
}

/* Optional: Hover effect for visual feedback */
.credential-box:hover {
  transform: scale(1.05);
  /* Slightly enlarge on hover */
  transition: transform 0.3s ease;
}

.page-container {
  background-image: url('@/assets/images/bg.svg');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 20px;
}

.form-container {
  background-color: rgba(26, 26, 46, 0.9);
  padding: 30px;
  border-radius: 8px;
  border: 1px solid #4e4e68;
  max-width: 500px;
  width: 100%;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.heading {
  color: #f8f9fa;
  text-align: center;
  margin-bottom: 20px;
}

.button-group {
  margin-top: 20px;
}

.button {
  background-color: #4e4e68;
  border-color: #4e4e68;
  color: #ffffff;
  padding: 10px;
  border-radius: 5px;
  cursor: pointer;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 10px;
}

.button img {
  margin-right: 10px;
  height: 20px;
  width: 20px;
}

.button:hover {
  background-color: #5e5e7f;
}
</style>
