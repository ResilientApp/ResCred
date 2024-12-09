<template>
  <div class="container custom-container">
  <h1 class = "heading_container_dashboard"> Credentials</h1>
    <!-- beggining of Modal for week 2-->
    <b-modal
  v-model="showImportModal"
  title="Import Credential"
  dialog-class="custom-modal"
>
  <b-form @submit.prevent="handleImport">
    <b-form-group label="Credential Data">
      <b-form-textarea
        v-model="importedCredential"
        required
      ></b-form-textarea>
    </b-form-group>
    <b-form-group label="Passphrase">
      <b-form-input
        type="password"
        v-model="passphrase"
        required
      ></b-form-input>
    </b-form-group>
    <b-button type="submit" variant="success">Import</b-button>
    <b-button
      variant="secondary"
      class="ml-2"
      @click="showImportModal = false"
    >
      Cancel
    </b-button>
  </b-form>
</b-modal>



     <!-- END of Modal for week 2-->
    <b-container>
      <section class = "credential-section">

        <b-button variant="primary" class="mb-3" @click="showImportModal = true">Import Credential</b-button>
      <!-- Pending Section -->
      <h2 class="sub-heading">Pending</h2>
      <transition-group name="credential-card" tag="div" class="b-row">
        <b-col md="4" v-for="credential in pendingCredentials" :key="credential.id">
          <CredentialCard
            :credential="credential"
            @approve="openConfirmModal('approve', credential)"
            @reject="openConfirmModal('reject', credential)"
          />
        </b-col>
      </transition-group>
    </section>
      <section class = "credential-section">
      <!-- Approved Section -->
      <h2 class="sub-heading">Approved</h2>
      <transition-group name="credential-card" tag="div" class="b-row">
        <b-col md="4" v-for="credential in approvedCredentials" :key="credential.id">
          <CredentialCard :credential="credential" />
        </b-col>
      </transition-group>
      </section>
      <!-- Confirmation Modal -->
      <ConfirmationModal
      v-model:isVisible="isModalVisible"
      :title="modalTitle"
      :message="modalMessage"
      :actionType="actionType"
      :Credential="selectedCredential"
      @confirm="handleConfirm"
      />
    </b-container>
  </div>
</template>


<script lang="ts">
import { defineComponent, ref } from 'vue';
import CredentialCard from './CredentialCard.vue';
import ConfirmationModal from './ConfirmationModal.vue';
import apolloClient from '../graphql/apolloClient';
import { VERIFY_CREDENTIAL } from '../graphql/queries';


export default defineComponent({
  name: 'CredentialHolderDashboard',
  components: { CredentialCard, ConfirmationModal},
  setup() {
    const credentials = ref([
  { id: 1, name: 'Bachelor of Science in Computer Science', holder: 'Alice', issuer: 'University of Tech', domain: 'university.edu', status: 'pending' },
  { id: 2, name: 'Certified Cloud Practitioner', holder: 'Bob', issuer: 'AWS Certification', domain: 'aws.amazon.com', status: 'approved' },
  { id: 3, name: 'Professional Scrum Master', holder: 'Carol', issuer: 'Scrum.org', domain: 'scrum.org', status: 'pending' },
]);


//week 2 modal for import credentials

interface CredentialData {
  id: number;
  name: string;
  holder: string;
  issuer: string;
  domain: string;
  status: string;
}


const encryptCredential = (data: CredentialData, passphrase: string): string => {
  return btoa(`${JSON.stringify(data)}:${passphrase}`);
};


const handleImport = async () => {
  if (!importedCredential.value || !passphrase.value) {
    alert('Please fill in all fields.');
    return;
  }

  // Construct a CredentialData object
  const credentialData: CredentialData = {
    id: Date.now(), // Use a unique ID for now
    name: importedCredential.value.name || 'Unnamed Credential', // Adjust this based on your structure
    holder: 'Federico', // Replace with the actual holder name
    issuer: 'Example Issuer', // Replace with the actual issuer
    domain: 'example.com', // Replace with the actual domain
    status: 'pending',
  };

  const encryptedData = encryptCredential(credentialData, passphrase.value);
  console.log('Encrypted Credential:', encryptedData);

  try {
    const result = await Registry.importCredential(encryptedData);
    if (result.success) {
      alert('Credential imported successfully.');
      pendingCredentials.value.push(credentialData);
    } else {
      alert('Credential import failed: ' + result.message);
    }
  } catch (error) {
    console.error('Error importing credential:', error);
    alert('An error occurred while importing the credential.');
  }

  showImportModal.value = false;
  importedCredential.value = null;
  passphrase.value = '';
};



//END week 2 modal for import credentials

//graphql functions week2
const verifyCredential = async () => {
  try {
    const { data } = await apolloClient.query({
      query: VERIFY_CREDENTIAL,
      variables: { credentialData: importedCredential.value },
    });

    if (data.verifyCredential.valid) {
      alert('Credential is valid: ' + data.verifyCredential.message);
    } else {
      alert('Credential verification failed: ' + data.verifyCredential.message);
    }
  } catch (error) {
    console.error('Error verifying credential:', error);
    alert('An error occurred while verifying the credential.');
  }
};

//END graphql functions week2
const approvedCredentials = ref([
  {
    id: 1,
    name: 'Certified Cloud Practitioner',
    holder: 'Charlie',
    issuer: 'AWS Certification',
    domain: 'aws.amazon.com',
    status: 'approved',
  },
]);

const pendingCredentials = ref([
  {
    id: 2,
    name: 'Bachelor of Science',
    holder: 'Alice',
    issuer: 'University of Tech',
    domain: 'university.edu',
    status: 'pending',
  },
  {
    id: 3,
    name: 'Professional Scrum Master',
    holder: 'Bob',
    issuer: 'Scrum.org',
    domain: 'scrum.org',
    status: 'pending',
  },
]);

const approveCredential = async (credential: any) => {
  try {
    // Simulate using a backend function to approve the credential
    const result = await Registry.approveReq(credential, 'verifier-address-placeholder');
    if (result.success) {
      alert('Credential approved successfully.');
      // Move the credential to the approved list
      approvedCredentials.value = [
        ...approvedCredentials.value,
        { ...credential, status: 'approved' },
      ];
      pendingCredentials.value = pendingCredentials.value.filter(
        (item) => item.id !== credential.id
      );
    } else {
      alert('Credential approval failed: ' + result.message);
    }
  } catch (error) {
    console.error('Error approving credential:', error);
    alert('An error occurred while approving the credential.');
  }
};



const rejectCredential = async (credential: any) => {
  try {
    // Simulate using a backend function to reject the credential
    const result = await Registry.rejectReq(credential, 'verifier-address-placeholder');
    if (result.success) {
      alert('Credential rejected successfully.');
      // Remove the credential from the pending list
      pendingCredentials.value = pendingCredentials.value.filter(
        (item) => item.id !== credential.id
      );
    } else {
      alert('Credential rejection failed: ' + result.message);
    }
  } catch (error) {
    console.error('Error rejecting credential:', error);
    alert('An error occurred while rejecting the credential.');
  }
};



const handleConfirm = () => {
  if (actionType.value === 'approve' && selectedCredential.value) {
    // Approve the credential
    approvedCredentials.value = [
      ...approvedCredentials.value,
      { ...selectedCredential.value, status: 'approved' },
    ];
    // Remove from pending list
    pendingCredentials.value = pendingCredentials.value.filter(
      (credential) => credential.id !== selectedCredential.value?.id
    );
  } else if (actionType.value === 'reject' && selectedCredential.value) {
    // Remove the rejected credential from the pending list
    pendingCredentials.value = pendingCredentials.value.filter(
      (credential) => credential.id !== selectedCredential.value?.id
    );
  }

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
    const importedCredential = ref<{ name: string } | null>(null);
    const passphrase = ref('');
    const modalTitle = ref('');
    const modalMessage = ref('');
    const selectedCredential = ref<Credential | null>(null);
    const actionType = ref('');
    const isModalVisible = ref(false);
    const confirmationModal = ref<{ isVisible: boolean } | null>(null);



const openConfirmModal = (action: string, credential: any) => {ref(null); // Reference to modal
  console.log('Event Triggered:', action, credential); // Debug Log
  modalTitle.value = action === 'approve' ? 'Approve Credential' : 'Reject Credential';
  modalMessage.value = `Are you sure you want to ${action} the credential "${credential.name}"?`;
  actionType.value = action;
  selectedCredential.value = credential;
  isModalVisible.value = true;
  console.log('Modal Visibility:', isModalVisible.value); // Debug Log
};
    return {
      credentials,
      modalTitle,
      modalMessage,
      openConfirmModal,
      handleConfirm,
      confirmationModal, // Return modal reference
      approvedCredentials, // Return computed property
      pendingCredentials,
      isModalVisible,
      approveCredential,
      actionType,
      rejectCredential,
      selectedCredential,
      showImportModal,
      importedCredential,
      passphrase,
      handleImport,
    };
  },
});
</script>

<style scoped>
.custom-container {
  max-width: 100%; /* Override Bootstrap's default max-width */
  width: 100%;
}

</style>