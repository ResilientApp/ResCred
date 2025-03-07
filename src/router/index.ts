// router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import CredentialForm from '../components/CredentialForm.vue'; // Adjust path if necessary
import Dashboard from '../components/Dashboard.vue'; // Adjust path if necessary
// import ViewCredential from '../components/CredentialHolderDashboard.vue'; // Adjust path if necessary
import CreateContract from '../components/CreateContract.vue'; // Adjust path if necessary
import CredentialHolderDashboard from '../components/CredentialHolderDashboard.vue';
import Login from '../components/Login.vue'; // Adjust path if necessary
import trackCredential from '../components/TrackStatus.vue'; // Adjust path if necessary

const routes = [
  { path: '/', name: 'Dashboard', component: Dashboard },
  { path: '/login', name: 'Login', component: Login },
  { path: '/verify', name: 'CredentialForm', component: CredentialForm },
  { path: '/view', name: 'CredentialHolderDashboard', component: CredentialHolderDashboard },
  { path: '/issue', name: 'CreateContract', component: CreateContract },
  { path: '/verify-track', name: 'TrackStatus', component: trackCredential },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;
