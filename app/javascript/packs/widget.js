import Vue from 'vue';
import store from '../widget/store';
import App from '../widget/App.vue';
import router from '../widget/router';

Vue.config.productionTip = false;
window.onload = () => {
  window.WOOT = new Vue({
    router,
    store,
    render: h => h(App),
  }).$mount('#app');
};
