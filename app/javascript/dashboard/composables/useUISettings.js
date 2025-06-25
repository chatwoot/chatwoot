import { computed } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

export const DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER = Object.freeze([
  { name: 'conversation_actions' },
  { name: 'macros' },
  { name: 'conversation_info' },
  { name: 'contact_attributes' },
  { name: 'contact_notes' },
  { name: 'previous_conversation' },
  { name: 'conversation_participants' },
  { name: 'shopify_orders' },
]);

export const DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER = Object.freeze([
  { name: 'contact_attributes' },
  { name: 'contact_labels' },
  { name: 'previous_conversation' },
]);

/**
 * Slugifies the channel name.
 * Replaces spaces, hyphens, and double colons with underscores.
 * @param {string} name - The channel name to slugify.
 * @returns {string} The slugified channel name.
 */
const slugifyChannel = name =>
  name?.toLowerCase().replace(' ', '_').replace('-', '_').replace('::', '_');

/**
 * Computes the order of items in the conversation sidebar, using defaults if not present.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {Array} Ordered list of sidebar items.
 */
const useConversationSidebarItemsOrder = uiSettings => {
  return computed(() => {
    const { conversation_sidebar_items_order: itemsOrder } = uiSettings.value;
    // If the sidebar order is not set, use the default order.
    if (!itemsOrder) {
      return [...DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER];
    }
    // Create a copy of itemsOrder to avoid mutating the original store object.
    const itemsOrderCopy = [...itemsOrder];
    // If the sidebar order doesn't have the new elements, then add them to the list.
    DEFAULT_CONVERSATION_SIDEBAR_ITEMS_ORDER.forEach(item => {
      if (!itemsOrderCopy.find(i => i.name === item.name)) {
        itemsOrderCopy.push(item);
      }
    });
    return itemsOrderCopy;
  });
};

/**
 * Computes the order of items in the contact sidebar,using defaults if not present.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {Array} Ordered list of sidebar items.
 */
const useContactSidebarItemsOrder = uiSettings => {
  return computed(() => {
    const { contact_sidebar_items_order: itemsOrder } = uiSettings.value;
    return itemsOrder || DEFAULT_CONTACT_SIDEBAR_ITEMS_ORDER;
  });
};

/**
 * Toggles the open state of a sidebar item.
 * @param {string} key - The key of the sidebar item to toggle.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @param {Function} updateUISettings - Function to update UI settings.
 */
const toggleSidebarUIState = (key, uiSettings, updateUISettings) => {
  updateUISettings({ [key]: !uiSettings.value[key] });
};

/**
 * Sets the signature flag for a specific channel type in the inbox settings.
 * @param {string} channelType - The type of the channel.
 * @param {boolean} value - The value to set for the signature enabled flag.
 * @param {Function} updateUISettings - Function to update UI settings.
 */
const setSignatureFlagForInbox = (channelType, value, updateUISettings) => {
  if (!channelType) return;

  const slugifiedChannel = slugifyChannel(channelType);
  updateUISettings({ [`${slugifiedChannel}_signature_enabled`]: value });
};

/**
 * Fetches the signature flag for a specific channel type from UI settings.
 * @param {string} channelType - The type of the channel.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {boolean} The value of the signature enabled flag.
 */
const fetchSignatureFlagFromUISettings = (channelType, uiSettings) => {
  if (!channelType) return false;

  const slugifiedChannel = slugifyChannel(channelType);
  return uiSettings.value[`${slugifiedChannel}_signature_enabled`];
};

/**
 * Checks if a specific editor hotkey is enabled.
 * @param {string} key - The key to check.
 * @param {Object} uiSettings - Reactive UI settings object.
 * @returns {boolean} True if the hotkey is enabled, otherwise false.
 */
const isEditorHotKeyEnabled = (key, uiSettings) => {
  const {
    editor_message_key: editorMessageKey,
    enter_to_send_enabled: enterToSendEnabled,
  } = uiSettings.value || {};
  if (!editorMessageKey) {
    return key === (enterToSendEnabled ? 'enter' : 'cmd_enter');
  }
  return editorMessageKey === key;
};

/**
 * Main composable function for managing UI settings.
 * @returns {Object} An object containing reactive properties and methods for UI settings management.
 */
export function useUISettings() {
  const getters = useStoreGetters();
  const store = useStore();
  const uiSettings = computed(() => getters.getUISettings.value);

  const updateUISettings = (settings = {}) => {
    store.dispatch('updateUISettings', {
      uiSettings: {
        ...uiSettings.value,
        ...settings,
      },
    });
  };

  return {
    uiSettings,
    updateUISettings,
    conversationSidebarItemsOrder: useConversationSidebarItemsOrder(uiSettings),
    contactSidebarItemsOrder: useContactSidebarItemsOrder(uiSettings),
    isContactSidebarItemOpen: key => !!uiSettings.value[key],
    toggleSidebarUIState: key =>
      toggleSidebarUIState(key, uiSettings, updateUISettings),
    setSignatureFlagForInbox: (channelType, value) =>
      setSignatureFlagForInbox(channelType, value, updateUISettings),
    fetchSignatureFlagFromUISettings: channelType =>
      fetchSignatureFlagFromUISettings(channelType, uiSettings),
    isEditorHotKeyEnabled: key => isEditorHotKeyEnabled(key, uiSettings),
  };
}
