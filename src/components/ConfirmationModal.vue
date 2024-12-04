<template>
  <!-- Modal for importing credentials -->
  <b-modal v-model="isImportModalVisible" title="Import Credential" class="custom-modal">
    <b-form @submit.prevent="handleCredentialImport">
      <b-form-group label="Credential Data">
        <b-form-textarea v-model="importedCredential" required></b-form-textarea>
      </b-form-group>
      <b-form-group label="Passphrase">
        <b-form-input type="password" v-model="passphrase" required></b-form-input>
      </b-form-group>
      <b-button type="submit" variant="primary">Import</b-button>
    </b-form>
  </b-modal>

  <!-- Confirmation modal -->
  <b-modal
    v-model="localIsVisible"
    :title="title"
    class="custom-modal"
    @hide="handleClose"
  >
    <p>{{ message }}</p>
    <b-button variant="primary" @click="confirmAction">Confirm</b-button>
    <b-button variant="secondary" @click="handleClose">Cancel</b-button>
  </b-modal>
</template>

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';

export default defineComponent({
  name: 'ConfirmationModal',
  props: {
    title: {
      type: String,
      default: 'Confirmation',
    },
    message: {
      type: String,
      default: 'Are you sure you want to proceed?',
    },
    isVisible: {
      type: Boolean,
      default: false,
    },
    actionType: {
      type: String,
      default: '',
    },
    credential: {
      type: Object,
      default: null,
    },
  },
  emits: ['confirm', 'update:isVisible'],
  setup(props, { emit }) {
    const localIsVisible = ref(props.isVisible);
    const isImportModalVisible = ref(false);
    const importedCredential = ref('');
    const passphrase = ref('');
    const modalTitle = ref('');
    const modalMessage = ref('');

    watch(
      () => props.isVisible,
      (newValue) => {
        localIsVisible.value = newValue;
      }
    );

    const confirmAction = () => {
      emit('confirm', {
        action: props.actionType,
        credential: props.credential,
      });
      localIsVisible.value = false;
      emit('update:isVisible', false);
    };

    const handleClose = () => {
      localIsVisible.value = false;
      emit('update:isVisible', false);
    };

    const handleCredentialImport = () => {
      if (importedCredential.value && passphrase.value) {
        console.log('Credential Imported:', importedCredential.value);
        console.log('Passphrase:', passphrase.value);
        isImportModalVisible.value = false;
      }
    };

    return {
      localIsVisible,
      isImportModalVisible,
      importedCredential,
      passphrase,
      confirmAction,
      handleClose,
      handleCredentialImport,
      modalTitle,
      modalMessage,
    };
  },
});
</script>

<style scoped>
.custom-modal {
  background-color: rgba(26, 26, 46, 0.95);
  color: #f8f9fa;
  border: 1px solid #4e4e68;
}

.custom-modal .modal-content {
  background-color: rgba(26, 26, 46, 0.95);
  border-radius: 8px;
}

.custom-modal .modal-footer {
  border-top: 1px solid #4e4e68;
}
</style>
