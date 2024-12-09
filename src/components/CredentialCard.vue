<template>
  <b-card :title="credential.granteeName" class="mb-3 b-card" sub-title="Holder: {{ credential.holder }}"
    bg-variant="primary">
    <b-card-text>
      <strong>Credential Grant Address:</strong> {{ credential.address.substring(2).replace(/^0+/, '') }}
      <strong>Credential Address</strong> {{ credential.credentialAddr.substring(2).replace(/^0+/, '') }}<br />
      <strong>Expiry:</strong> {{ credential.expiry == 0 ? "never" : new Date(credential.expiry *
        1000).toLocaleDateString() }}<br />
    </b-card-text>

    <!-- Badge for Status -->
    <!-- <b-badge :variant="credential.status === 'pending' ? 'warning' : 'success'" class="mb-3 status-badge">
      {{ credential.status }}
    </b-badge> -->


    <!-- Conditionally render the buttons -->
    <!-- <div v-if="credential.status === 'pending'">
      <b-button variant="success" @click="$emit('approve', credential)">Approve</b-button>
      <b-button variant="danger" @click="$emit('reject', credential)">Reject</b-button>
    </div> -->
  </b-card>
</template>
<script lang="ts">
import { defineComponent, PropType } from 'vue';
import { CredentialGrant } from '../api/registry';

export default defineComponent({
  name: 'CredentialCard',
  props: {
    credential: {
      // type: Object as PropType<{ grantee: string; holder: string; issuer: string; domain: string; status: string; }>,
      type: Object as PropType<CredentialGrant>,
      required: true,
    },
  },
  emits: ['approve', 'reject'],
});

</script>

<style scoped>
.mb-3 {
  margin-bottom: 1rem;
  /* Ensure spacing between cards */
}

/* Add specific custom styles here, if necessary */
</style>
