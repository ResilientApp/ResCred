<template>
  <div class="form-container">
    <h2 class="heading">Track Credential Status</h2>

    <!-- Loading spinner when status is being fetched -->
    <div v-if="loading" class="loading-spinner"></div>

    <div v-if="!loading && credentialStatus">
      <!-- Apply status color to the whole line -->
      <p :class="statusClass">
        Status for Credential ID {{ credentialId }}: {{ credentialStatus }}
      </p>
    </div>

    <div v-else-if="!loading">
      <p class="status-not-found">No status found for the provided Credential ID.</p>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, computed, ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';

export default defineComponent({
  name: 'TrackStatus',
  setup() {
    const route = useRoute();
    const credentialId = route.query.credentialId as string;
    const loading = ref(true);  // To track loading state
    const credentialStatus = ref('');  // Mocking the status

    const statusClass = computed(() => {
      if (!credentialStatus.value) {
        return 'status-not-found'; // Apply this class when no status is found
      }
      switch (credentialStatus.value) {
        case 'Verified':
          return 'status-verified';
        case 'Pending':
          return 'status-pending';
        case 'Rejected':
          return 'status-rejected';
        default:
          return 'status-not-found';
      }
    });

    // Simulate loading and mock the response after 2 seconds
    onMounted(() => {
      setTimeout(() => {
        // credentialStatus.value = 'Rejected';  // Simulate a verified credential status
        loading.value = false;
      }, 2000);  // Simulate a 2-second delay
    });

    return {
      credentialId,
      credentialStatus,
      statusClass,
      loading,
    };
  },
});
</script>

<style scoped>
.form-container {
  text-align: center;  /* Center align all content in the form-container */
}

.status-verified {
  color: green;
  font-weight: bold;
}

.status-pending {
  color: orange;
  font-weight: bold;
}

.status-rejected {
  color: red;
  font-weight: bold;
}

.status-not-found {
  color: rgb(111, 111, 111);
  font-weight: bold;
}

/* Blue spinning circle */
.loading-spinner {
  border: 4px solid #f3f3f3; /* Light gray background for the circle */
  border-top: 4px solid #3498db; /* Blue color for the spinner */
  border-radius: 50%;  /* Make it round */
  width: 40px; /* Size of the spinner */
  height: 40px; /* Size of the spinner */
  animation: spin 1s linear infinite; /* Spin animation */
  margin: 0 auto;
}

/* Create the spinning effect */
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
