import { defineCustomElement } from 'vue';
import VueHelloWorld from './VueHelloWorld.vue';

// Convert Vue component to Web Component
const VueHelloWorldElement = defineCustomElement(VueHelloWorld);

// Register Web Components
export const registerVueWebComponents = () => {
  // Check if already registered to prevent errors
  if (!customElements.get('vue-hello-world')) {
    customElements.define('vue-hello-world', VueHelloWorldElement);
    // eslint-disable-next-line no-console
    console.log('✅ Registered vue-hello-world Web Component');
  }
};

// Export for manual registration if needed
export { VueHelloWorldElement };
