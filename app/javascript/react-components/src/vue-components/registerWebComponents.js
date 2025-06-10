import { defineCustomElement } from 'vue';
import VueHelloWorld from './VueHelloWorld.vue';
import ChatwootMessageListWebComponent from './ChatwootMessageListWebComponent.vue';

// Convert Vue components to Web Components
const VueHelloWorldElement = defineCustomElement(VueHelloWorld);
const ChatwootMessageListElement = defineCustomElement(
  ChatwootMessageListWebComponent
);

// Register Web Components
export const registerVueWebComponents = () => {
  // Check if already registered to prevent errors
  if (!customElements.get('vue-hello-world')) {
    customElements.define('vue-hello-world', VueHelloWorldElement);
    // eslint-disable-next-line no-console
    console.log('✅ Registered vue-hello-world Web Component');
  }

  if (!customElements.get('chatwoot-message-list')) {
    customElements.define('chatwoot-message-list', ChatwootMessageListElement);
    // eslint-disable-next-line no-console
    console.log('✅ Registered chatwoot-message-list Web Component');
  }
};

// Export for manual registration if needed
export { VueHelloWorldElement, ChatwootMessageListElement };
