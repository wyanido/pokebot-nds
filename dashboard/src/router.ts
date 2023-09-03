import { createRouter, createWebHistory } from 'vue-router';
import Dashboard from './Dashboard.vue';
import Config from './Config.vue';

const routes = [
    {
        path: '/',
        component: Dashboard,
    },
    {
        path: '/config',
        component: Config,
    },
];

const router = createRouter({
    history: createWebHistory(),
    routes,
});

export default router;
