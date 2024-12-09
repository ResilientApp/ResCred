<template>
  <div class="form-container">
    <h1 class="heading">Submit Credential</h1>
    <form @submit.prevent="handleSubmit">
      <input type="text" v-model="credentialId" placeholder="Enter Credential ID" class="form-control" />
      <input type="text" v-model="contactAddress" placeholder="Enter Contact Address" class="form-control" />
      <div class="button-group">
        <button type="submit" class="button">Submit</button>
        <button type="button" class="button" @click="goToTrack">Track</button>
      </div>
    </form>

    <!-- Success message -->
    <div v-if="submitted" class="success-message">
      Credential submitted successfully!
    </div>

    <!-- Error message -->
    <div v-if="error" class="error-message">
      Both Credential ID and Contact Address are required.
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useRouter } from 'vue-router';
import { RegistryClient, IssuingBodyClient } from '../api/registry.ts';

const test = async () => {
  // const accnt = await IssuingBodyClient.createAccount();
  // console.log(await IssuingBodyClient.registerIssuingBody("grub","hub", accnt))
  // console.log("bloop");
  // const accnt = await IssuingBodyClient.createAccount();
  // console.log(accnt.publicKey);
  // IssuingBodyClient.registryAddress = await IssuingBodyClient.createContract(`${accnt.publicKey}`, "Registry");
  // // console.log(await IssuingBodyClient.createContract((await IssuingBodyClient.createAccount()).publicKey, "Registry"));
  // const ibOwner = (await IssuingBodyClient.createAccount()).publicKey;
  // const ib = (await IssuingBodyClient.createContract(ibOwner, "IssuingBody", `${IssuingBodyClient.registryAddress},'huh','wha'`));
  // console.log(`ibOwner: ${ibOwner}`);
  // console.log(`ib: ${ib}`);
  // const pp = await IssuingBodyClient.executeContract(ibOwner, RegistryClient.registryAddress, "registerIssuingBody(address)", ib);
  // console.log(pp);
  // console.log("bleep");
  const pair = await IssuingBodyClient.createAccount();
  const hello = await IssuingBodyClient.registerIssuingBody("blahbaldy","ok",pair);
  console.log(hello);
}

export default defineComponent({
  name: 'CredentialForm',
  data() {
    return {
      credentialId: '',
      contactAddress: '',
      submitted: false,
      error: false,
    };
  },
  methods: {
    handleSubmit() {
      // IssuingBodyClient.createAccount();
      test();
      // Check if both fields are filled
      if (!this.credentialId || !this.contactAddress) {
        this.error = true;  // Show error message
        this.submitted = false;
        return;
      }

      // If both fields are filled, submit the credential
      this.submitted = true;  // Show success message
      this.error = false;

      // Logic for submitting credentials (e.g., sending to a backend)
      // For now, just mock this with an alert
      alert('Credential Submitted!');

      // Reset form fields after submission
      this.credentialId = '';
      this.contactAddress = '';
    },
    goToTrack() {
      this.$router.push({ name: 'TrackStatus', query: { credentialId: this.credentialId } });
    },
  },
});
</script>

<style scoped>
.form-container {
  text-align: center;
  /* Center align all content in the form-container */
}

.success-message {
  margin-top: 20px;
  color: green;
  font-weight: bold;
}

.error-message {
  margin-top: 20px;
  color: red;
  font-weight: bold;
}
</style>
