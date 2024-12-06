<template>
  <button
    class="button"
    @click="trackCredential"
  >
    Track
  </button>
</template>

<script lang="ts">
import { defineComponent, reactive } from 'vue';
import { useRouter } from 'vue-router';

export default defineComponent({
  name: 'VerifierApp',
  setup() {
    const router = useRouter();
    const form = reactive({
      credentialId: '',
    });

    const trackCredential = () => {
      if (form.credentialId) {
        router.push({ path: '/track-status', query: { credentialId: form.credentialId } });
      } else {
        alert('Please enter a Credential ID.');
      }
    };

    return {
      form,
      trackCredential,
    };
  },
});
</script>
