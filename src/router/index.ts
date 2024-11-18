import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router';
import CreateContract from "../components/CreateContract.vue";
import Home from '../components/Home.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    name: 'Home',
    component: Home,
  },
  {
    path: '/create-contract',
    name: 'CreateContract',
    component: CreateContract,
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/',
  },
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
});

export default router;