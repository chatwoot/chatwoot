import { computed } from 'vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';

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

const slugifyChannel = name =>
  name?.toLowerCase().replace(' ', '_').replace('-', '_').replace('::', '_');

/**
 * Composable to manage UI settings related to user interface elements in the dashboard.
 * @returns {Object} An object containing reactive properties and methods for UI settings management.
 */
export function useUiSettings() {
  const getters = useStoreGetters();
  const store = useStore();

  const uiSettings = computed(() => getters.getUISettings.value);

  /**
   * Updates UI settings in the Vuex store.
   * @param {Object} settings - New settings to merge with existing settings.
   */
  const updateUISettings = (settings = {}) => {
    store.dispatch('updateUISettings', {
      uiSettings: {
        ...uiSettings.value,
        ...settings,
      },
    });
  };

  /**
   * Computes the order of items in the conversation sidebar, adding default items if not present.
   * @returns {Array} Ordered list of sidebar items.
   */
  const conversationSidebarItemsOrder = computed(() => {
    const { conversation_sidebar_items_order: itemsOrder } = uiSettings.value;
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
  });

  /**
   * Computes the order of items in the contact sidebar, using defaults if not set.
   * @returns {Array} Ordered list of sidebar items.
   */
  const contactSidebarItemsOrder = computed(() => {
    const { contact_sidebar_items_order: itemsOrder } = uiSettings.value;
    return itemsOrder || DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER;
  });

  /**
   * Determines if a specific sidebar item is open based on its key.
   * @param {string} key - The key of the sidebar item.
   * @returns {boolean} True if the item is open, otherwise false.
   */
  const isContactSidebarItemOpen = key => {
    return !!uiSettings.value[key];
  };

  /**
   * Toggles the open state of a sidebar item.
   * @param {string} key - The key of the sidebar item to toggle.
   */
  const toggleSidebarUIState = key => {
    updateUISettings({ [key]: !isContactSidebarItemOpen(key) });
  };

  /**
   * Sets the signature flag for a specific channel type in the inbox settings.
   * @param {string} channelType - The type of the channel.
   * @param {boolean} value - The value to set for the signature enabled flag.
   */
  const setSignatureFlagForInbox = (channelType, value) => {
    if (!channelType) return;

    const slugifiedChannel = slugifyChannel(channelType);
    updateUISettings({ [`${slugifiedChannel}_signature_enabled`]: value });
  };

  /**
   * Fetches the signature flag for a specific channel type from UI settings.
   * @param {string} channelType - The type of the channel.
   * @returns {boolean} The value of the signature enabled flag.
   */
  const fetchSignatureFlagFromUiSettings = channelType => {
    if (!channelType) return false;

    const slugifiedChannel = slugifyChannel(channelType);
    return uiSettings.value[`${slugifiedChannel}_signature_enabled`];
  };

  /**
   * Checks if a specific editor hotkey is enabled.
   * @param {string} key - The key to check.
   * @returns {boolean} True if the hotkey is enabled, otherwise false.
   */
  const isEditorHotKeyEnabled = key => {
    const {
      editor_message_key: editorMessageKey,
      enter_to_send_enabled: enterToSendEnabled,
    } = uiSettings.value || {};
    if (!editorMessageKey) {
      if (enterToSendEnabled) {
        return key === 'enter';
      }
      return key === 'cmd_enter';
    }
    return editorMessageKey === key;
  };

  return {
    uiSettings,
    updateUISettings,
    conversationSidebarItemsOrder,
    contactSidebarItemsOrder,
    isContactSidebarItemOpen,
    toggleSidebarUIState,
    setSignatureFlagForInbox,
    fetchSignatureFlagFromUiSettings,
    isEditorHotKeyEnabled,
  };
}
