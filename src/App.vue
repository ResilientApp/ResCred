<template>
  <div id="app" class="page-container">
    <!-- Navigation bar or any other header components can go here -->
    <router-view></router-view> <!-- This will render the routed components -->
  </div>
</template>

<script>
export default {
  name: 'App',
};
</script>

<style scoped>
/* Import the global CSS file */
@import './App.css';
</style>
