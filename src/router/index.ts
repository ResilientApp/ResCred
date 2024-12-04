import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import Home from '../components/Home.vue';
import CredentialHolderDashboard from '/home/elpilotoferoz/ECS_189_project/tinker/ecs189f/src/components/CredentialHolderDashboard.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: Home,
  },
  {
    path: '/dashboard',
    name: 'CredentialHolderDashboard',
    component: CredentialHolderDashboard,
  },
  {
    path: '/:pathMatch(.*)*', // Catch-all route
    redirect: '/',
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

export default router;
