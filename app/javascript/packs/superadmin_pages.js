import 'chart.js';
import Vue from 'vue';
import VueDOMPurifyHTML from 'vue-dompurify-html';
Vue.use(VueDOMPurifyHTML);

const PlaygroundIndex = () =>
  import('../superadmin_pages/views/playground/Index.vue');

const ComponentMapping = {
  PlaygroundIndex: PlaygroundIndex,
};

const renderComponent = (componentName, props) => {
  Vue.component(componentName, ComponentMapping[componentName]);
  new Vue({
    data: { props: props },
    template: `<${componentName} :component-data="props"/>`,
  }).$mount('#app');
};

document.addEventListener('DOMContentLoaded', () => {
  const element = document.getElementById('app');
  if (element) {
    const componentName = element.dataset.componentName;
    const props = JSON.parse(element.dataset.props);
    renderComponent(componentName, props);
  }
});
