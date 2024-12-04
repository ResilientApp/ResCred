// src/main.ts
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';
import store from './store';
import 'bootstrap/dist/css/bootstrap.min.css';
import 'bootstrap';
import BootstrapVue3 from 'bootstrap-vue-3';
import 'bootstrap-vue-3/dist/bootstrap-vue-3.css';
import './App.css';

async function initializeApp() {
  const app = createApp(App);
  app.use(store);
  app.use(router);
  app.use(BootstrapVue3);
  
  // Wait for store initialization if needed
  await store.dispatch('initializeAuth');

  // Mount the app after initialization
  app.mount('#app');
}

// Call the initialization function
initializeApp();
