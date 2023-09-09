import { createApp } from 'vue';
import Dashboard from './Dashboard.vue';
import Config from './Config.vue';

// Import Font Awesome icons
import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { faUserCircle, faGear, faWrench, faCircleArrowUp, faCircleArrowDown, faSave, faInfoCircle } from '@fortawesome/free-solid-svg-icons'

library.add(faUserCircle, faGear, faWrench, faCircleArrowUp, faCircleArrowDown, faSave, faInfoCircle)

// Route .vue pages to respective paths
import { createRouter, createWebHistory } from "vue-router";

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/',
            component: Dashboard,
        },
        {
            path: '/config',
            component: Config,
        },
    ],
});

// Initialise
createApp({})
    .component('font-awesome-icon', FontAwesomeIcon)
    .use(router)
    .mount("#app");
