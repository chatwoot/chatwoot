import { defineCustomElement } from 'vue';
import tailwindStyles from '../../../dashboard/assets/scss/_woot.scss?inline';
import ChatwootMessageListWebComponent from './ChatwootMessageListWebComponent.vue';
import en from '../../../dashboard/i18n/locale/en';
import { createI18n } from 'vue-i18n';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en,
  },
});

const ceOptions = {
  configureApp(app) {
    app.use(i18n);
  },
  // Include tailwind styles in the shadow DOM of each custom element
  styles: [tailwindStyles],
};

// Convert Vue components to Web Components
const ChatwootMessageListElement = defineCustomElement(
  ChatwootMessageListWebComponent,
  ceOptions
);

// Register Web Components
export const registerVueWebComponents = () => {
  if (!customElements.get('chatwoot-message-list')) {
    customElements.define('chatwoot-message-list', ChatwootMessageListElement);
    // eslint-disable-next-line no-console
    console.log('✅ Registered chatwoot-message-list Web Component');
  }
};

// Export for manual registration if needed
export { ChatwootMessageListElement };
