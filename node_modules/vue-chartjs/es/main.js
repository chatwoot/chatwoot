import Vue from 'vue';
import App from './examples/App';
new Vue({
  render: function render(h) {
    return h(App);
  }
}).$mount('#app');