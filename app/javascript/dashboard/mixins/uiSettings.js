import { mapGetters } from 'vuex';
export const DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER = [
  { name: 'conversation_actions' },
  { name: 'conversation_info' },
  { name: 'contact_attributes' },
  { name: 'previous_conversation' },
];
export const DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER = [
  { name: 'contact_attributes' },
  { name: 'contact_labels' },
  { name: 'previous_conversation' },
];
export default {
  computed: {
    ...mapGetters({
      uiSettings: 'getUISettings',
    }),
    conversationSidebarItemsOrder() {
      const { conversation_sidebar_items_order: itemsOrder } = this.uiSettings;
      return itemsOrder || DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER;
    },
    contactSidebarItemsOrder() {
      const { contact_sidebar_items_order: itemsOrder } = this.uiSettings;
      return itemsOrder || DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER;
    },
  },
  methods: {
    updateUISettings(uiSettings = {}) {
      this.$store.dispatch('updateUISettings', {
        uiSettings: {
          ...this.uiSettings,
          ...uiSettings,
        },
      });
    },
    isContactSidebarItemOpen(key) {
      const { [key]: isOpen } = this.uiSettings;
      return !!isOpen;
    },
    toggleSidebarUIState(key) {
      this.updateUISettings({ [key]: !this.isContactSidebarItemOpen(key) });
    },
  },
};
