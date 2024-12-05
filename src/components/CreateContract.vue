<template>
  <div class="container mt-5">
    <!-- Page Title -->
    <h1 class="text-center mb-5 display-4">Smart Contract Management</h1>

    <div class="row">
      <!-- Create Contract Section -->
      <div class="col-md-6 mb-5">
        <div class="card shadow-sm">
          <div class="card-header bg-primary text-white">
            <h4>Create Smart Contract</h4>
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
              <button type="submit" class="btn btn-outline-primary w-100">
                <i class="fas fa-plus-circle"></i> Create Contract
              </button>
            </form>
          </div>
        </div>
      </div>

      <!-- Issue Credentials Section -->
      <div class="col-md-6 mb-5">
        <div class="card shadow-sm">
          <div class="card-header bg-success text-white">
            <h4>Issue Credentials</h4>
          </div>
          <div class="card-body">
            <form @submit.prevent="createCred">
              <div class="mb-3">
                <label for="credName" class="form-label">Credential Name</label>
                <input type="text" id="credName" v-model="credName" class="form-control"
                  placeholder="Enter credential holder name" required />
              </div>
              <button type="submit" class="btn btn-outline-success w-100">
                <i class="fas fa-id-card"></i> Create Credential
              </button>
            </form>
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <!-- Owned Contracts Section -->
      <div class="col-lg-6 mb-5">
        <div class="card shadow-sm">
          <div class="card-header bg-info text-white">
            <h4>Owned Smart Contracts</h4>
          </div>
          <div class="card-body">
            <ul class="list-group">
              <li class="list-group-item d-flex justify-content-between align-items-center"
                v-for="contract in ownedContracts" :key="contract.id">
                <div>
                  <strong>{{ contract.name }}</strong>
                  <p class="mb-1 text-muted">Address: {{ contract.address }}</p>
                  <p class="small text-muted">Metadata: {{ contract.metadata }}</p>
                </div>
                <button class="btn btn-outline-danger btn-sm" @click="deleteContract(contract.id)">
                  <i class="fas fa-trash-alt"></i> Delete
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Issued Credentials Section -->
      <div class="col-lg-6 mb-5">
        <div class="card shadow-sm">
          <div class="card-header bg-warning text-dark">
            <h4>Issued Credentials</h4>
          </div>
          <div class="card-body">
            <ul class="list-group">
              <li class="list-group-item d-flex justify-content-between align-items-center"
                v-for="cred in issuedCredentials" :key="cred.id">
                <div>
                  <strong>{{ cred.name }}</strong>
                </div>
                <button class="btn btn-outline-danger btn-sm" @click="deleteCred(cred.id)">
                  <i class="fas fa-trash-alt"></i> Delete
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { v4 as uuidv4 } from "uuid";
import { defineComponent, ref } from "vue";

export default defineComponent({
  name: "CreateContract",
  setup() {
    const contractName = ref("");
    const constructorParam = ref("");
    const credName = ref("");
    const ownedContracts = ref([]);
    const issuedCredentials = ref([]);

    const deleteContract = (id: string) => {
      ownedContracts.value = ownedContracts.value.filter(
        (contract) => contract.id !== id
      );
    };

    const deleteCred = (id: string) => {
      issuedCredentials.value = issuedCredentials.value.filter(
        (cred) => cred.id !== id
      );
    };

    const createContract = () => {
      if (!contractName.value || !constructorParam.value) {
        alert("All fields are required.");
        return;
      }

      ownedContracts.value.push({
        id: uuidv4(),
        name: contractName.value,
        address: "x789...",
        metadata: constructorParam.value,
      });

      contractName.value = "";
      constructorParam.value = "";
    };

    const createCred = () => {
      if (!credName.value) {
        alert("Credential Name is required.");
        return;
      }

      issuedCredentials.value.push({
        id: uuidv4(),
        name: credName.value,
      });

      credName.value = "";
    };

    return {
      contractName,
      constructorParam,
      credName,
      ownedContracts,
      issuedCredentials,
      createContract,
      deleteContract,
      createCred,
      deleteCred,
    };
  },
});
</script>

<style scoped>
.card-header {
  font-size: 1.25rem;
}

.btn {
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
