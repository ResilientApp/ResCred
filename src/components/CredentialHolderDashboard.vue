<template>
  <h1 class = "heading_container_dashboard"> Credentials</h1>
  <div class="page-container">
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

  // Try to parse `importedCredential.value` into a valid `CredentialData`
  let parsedCredential: CredentialData;
  try {
    parsedCredential = JSON.parse(importedCredential.value);
  } catch (error) {
    alert('Invalid credential format.');
    return;
  }

  const encryptedData = encryptCredential(parsedCredential, passphrase.value);
  console.log('Encrypted Credential:', encryptedData);

  await verifyCredential();

  // Close modal and reset fields
  showImportModal.value = false;
  importedCredential.value = '';
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
const approveCredential = (credential: any) => {
  selectedCredential.value = credential;
  actionType.value = 'approve';
  modalTitle.value = 'Approve Credential';
  modalMessage.value = `Are you sure you want to approve ${credential.name}?`;

  if (confirmationModal.value) {
    confirmationModal.value.isVisible = true; // Safely access isVisible
  }
};

const rejectCredential = (credential: any) => {
  selectedCredential.value = credential;
  actionType.value = 'reject';
  modalTitle.value = 'Reject Credential';
  modalMessage.value = `Are you sure you want to reject "${credential.name}"?`;
    if (confirmationModal.value) {
      confirmationModal.value.isVisible = true;
    }
};

const handleConfirm = () => {
    if (actionType.value === 'approve' && selectedCredential.value) {
      approvedCredentials.value = [
        ...approvedCredentials.value,
        { ...selectedCredential.value , status: 'approved' },
      ];
      pendingCredentials.value = pendingCredentials.value.filter(
    (credential) => credential.id !== selectedCredential.value?.id
);

    }
    if (confirmationModal.value) {
      confirmationModal.value.isVisible = false; // Safely close the modal
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
    const importedCredential = ref('');
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
