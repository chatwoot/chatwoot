import { defineCustomElement } from 'vue';
import ChatwootMessageListWebComponent from './ChatwootMessageListWebComponent.vue';
import chatwootStyles from '../../../dashboard/assets/scss/app.scss?inline';
import multiselectStyles from 'vue-multiselect/dist/vue-multiselect.css?inline';
import floatingVueStyles from 'floating-vue/dist/style.css?inline';
import uploadStyles from '../styles/upload.css?inline';
import bubbleOverrideStyles from '../styles/bubble-overrides.css?inline';
import en from '../../../dashboard/i18n/locale/en';
import store from '../../../dashboard/store';
import vueActionCable from '../../../dashboard/helper/actionCable';
import { createI18n, I18nInjectionKey } from 'vue-i18n';

import VueDOMPurifyHTML from 'vue-dompurify-html';
import { domPurifyConfig } from 'shared/helpers/HTMLSanitizer.js';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en,
  },
});

const ceOptions = {
  configureApp(app) {
    app.use(store);
    app.use(VueDOMPurifyHTML, domPurifyConfig);

    // I18n has to be injected inside that can be picked
    // up by the compononent, the API stays the same, just use `useI18n`
    // https://vue-i18n.intlify.dev/guide/advanced/wc
    // Adding this link for my goldfish brain
    app.use(i18n);
    app.provide(I18nInjectionKey, i18n);
    // eslint-disable-next-line no-underscore-dangle
    vueActionCable.init(store, window.__PUBSUB_TOKEN__);
  },
  // bubbleOverrideStyles MUST be last to override _next-colors.scss
  styles: [
    chatwootStyles,
    multiselectStyles,
    floatingVueStyles,
    uploadStyles,
    bubbleOverrideStyles,
  ],
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
