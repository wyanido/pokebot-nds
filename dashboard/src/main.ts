import { createApp } from "vue";
import App from "./App.vue";

import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'

import { faUserCircle, faGear, faWrench } from '@fortawesome/free-solid-svg-icons'
library.add(faUserCircle, faGear, faWrench)

createApp(App).component('font-awesome-icon', FontAwesomeIcon).mount("#app");
