<template>
  <div class="container mt-5">
    <!-- Page Title -->
    <h1 class="text-center mb-4">Smart Contract Management</h1>

    <!-- Create Contract Section -->
    <div class="card mb-5">
      <div class="card-header">
        <h2>Create Smart Contract</h2>
      </div>
      <div class="card-body">
        <form @submit.prevent="createContract">
          <div class="mb-3">
            <label for="contractName" class="form-label">Contract Name</label>
            <input type="text" id="contractName" v-model="contractName" class="form-control"
              placeholder="Enter contract name" required />
          </div>
          <div class="mb-3">
            <label for="constructorParam" class="form-label">Constructor Parameter</label>
            <input type="text" id="constructorParam" v-model="constructorParam" class="form-control"
              placeholder="Enter parameter value" required />
          </div>
          <button type="submit" class="btn btn-primary">Create Contract</button>
        </form>
      </div>
    </div>

    <!-- Owned Contracts Section -->
    <div class="card mb-5">
      <div class="card-header">
        <h2>Owned Smart Contracts</h2>
      </div>
      <div class="card-body">
        <ul class="list-group">
          <li class="list-group-item d-flex justify-content-between align-items-center"
            v-for="contract in ownedContracts" :key="contract.id">
            <div>
              <strong>{{ contract.name }}</strong>
              <p class="mb-1">Address: {{ contract.address }}</p>
              <p>Metadata: {{ contract.metadata }}</p>
            </div>
            <button class="btn btn-danger btn-sm" @click="deleteContract(contract.id)">Delete</button>
          </li>
        </ul>
      </div>
    </div>

    <!-- Pending Verification Requests -->
    <div class="card">
      <div class="card-header">
        <h2>Pending Verification Requests</h2>
      </div>
      <div class="card-body">
        <ul class="list-group">
          <li class="list-group-item d-flex justify-content-between align-items-center"
            v-for="request in verificationRequests" :key="request.id">
            <div>
              <strong>{{ request.credentialName }}</strong>
              <p class="mb-1">Requested By: {{ request.requester }}</p>
              <p>Metadata: {{ request.metadata }}</p>
            </div>
            <div>
              <button class="btn btn-success me-2" @click="approveRequest(request.id)">
                Approve
              </button>
              <button class="btn btn-danger" @click="denyRequest(request.id)">
                Deny
              </button>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { v4 as uuidv4 } from 'uuid';
import { defineComponent, onMounted, onUnmounted, ref } from "vue";

export default defineComponent({
  name: "CreateContract",
  setup() {
    const contractName = ref("");
    const constructorParam = ref("");
    const ownedContracts = ref([
      {
        id: uuidv4(),
        name: "Contract A",
        address: "x123...",
        metadata: "Some metadata",
      },
      {
        id: uuidv4(),
        name: "Contract B",
        address: "x123...",
        metadata: "More metadata",
      },
    ]);
    const verificationRequests = ref([
      {
        id: uuidv4(),
        credentialName: "Credential X",
        requester: "User A",
        metadata: "Details",
      },
      {
        id: uuidv4(),
        credentialName: "Credential Y",
        requester: "User B",
        metadata: "More details",
      },
    ]);
    let intervalId: ReturnType<typeof setInterval>;

    onMounted(() => {
      intervalId = setInterval(createRequests, 5000);
    });

    onUnmounted(() => {
      clearInterval(intervalId);
    });

    const createRequests = () => {
      function getRandomLetter() {
        const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const randomIndex = Math.floor(Math.random() * letters.length);
        return letters[randomIndex];
      }

      const newReq = {
        id: uuidv4(),
        credentialName: `Credential ${getRandomLetter()}`,
        requester: `User ${getRandomLetter()}`,
        metadata: "More details",
      }

      verificationRequests.value.push(newReq);
    };

    const deleteContract = (id: string) => {
      ownedContracts.value = ownedContracts.value.filter(contract => contract.id !== id);
    }

    const createContract = () => {
      if (contractName.value.trim() === '' || constructorParam.value.trim() === '') {
        alert('Please fill out all fields.');
        return;
      }

      const newContract = {
        id: uuidv4(),
        name: contractName.value,
        address: "x123...",
        metadata: constructorParam.value
      };

      ownedContracts.value.push(newContract);

      contractName.value = '';
      constructorParam.value = '';

      console.log(
        "Contract created with:",
        contractName.value,
        constructorParam.value,
      );
    };

    const approveRequest = (id: string) => {
      verificationRequests.value = verificationRequests.value.filter(req => req.id !== id);
      console.log(`Approved request ID: ${id}`);
    };

    const denyRequest = (id: string) => {
      verificationRequests.value = verificationRequests.value.filter(req => req.id !== id);
      console.log(`Denied request ID: ${id}`);
    };

    return {
      contractName,
      constructorParam,
      ownedContracts,
      verificationRequests,
      createContract,
      approveRequest,
      denyRequest,
      deleteContract,
    };
  },
});
</script>

<style scoped></style>
