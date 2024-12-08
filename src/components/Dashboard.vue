<template>
  <div class="page-container">
    <div class="form-container">
      <h1 class="heading">Welcome to ResCred!</h1>

      <div class="button-group">
        <button class="button" @click="goToVerify">
          Verify Credential
        </button>

        <button class="button" @click="goToView">
          View Credential
        </button>

        <button class="button" @click="goToIssue">
          Issue Credential
        </button>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Home',
  methods: {
    goToVerify() {
      this.$router.push('/verify');
    },
    goToView() {
      this.$router.push('/view');
    },
    goToIssue() {
      this.$router.push('/issue');
    }
  }
};
</script>

<style scoped>
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
