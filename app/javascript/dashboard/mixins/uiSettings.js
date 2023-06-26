import { mapGetters } from 'vuex';
export const DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER = [
  { name: 'conversation_actions' },
  { name: 'macros' },
  { name: 'conversation_info' },
  { name: 'contact_attributes' },
  { name: 'previous_conversation' },
  { name: 'conversation_participants' },
];
export const DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER = [
  { name: 'contact_attributes' },
  { name: 'contact_labels' },
  { name: 'previous_conversation' },
];

export const isEditorHotKeyEnabled = (uiSettings, key) => {
  const {
    editor_message_key: editorMessageKey,
    enter_to_send_enabled: enterToSendEnabled,
  } = uiSettings || {};
  if (!editorMessageKey) {
    if (enterToSendEnabled) {
      return key === 'enter';
    }
    return key === 'cmd_enter';
  }
  return editorMessageKey === key;
};

export default {
  computed: {
    ...mapGetters({ uiSettings: 'getUISettings' }),
    conversationSidebarItemsOrder() {
      const { conversation_sidebar_items_order: itemsOrder } = this.uiSettings;
      // If the sidebar order is not set, use the default order.
      if (!itemsOrder) {
        return DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER;
      }
      // If the sidebar order doesn't have the new elements, then add them to the list.
      DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER.forEach(item => {
        if (!itemsOrder.find(i => i.name === item.name)) {
          itemsOrder.push(item);
        }
      });
      return itemsOrder;
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
