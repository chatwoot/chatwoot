import { computed, watch } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

/**
 * Heycommerce: Composable for managing contact labels (used in conversation sidebar)
 * This uses contact labels instead of conversation labels
 * @returns {Object} An object containing methods and computed properties for contact labels
 */
export function useContactLabels() {
  const store = useStore();
  const getters = useStoreGetters();

  /**
   * The currently selected chat
   * @type {import('vue').ComputedRef<Object>}
   */
  const currentChat = computed(() => getters.getSelectedChat.value);

  /**
   * The ID of the contact associated with the conversation
   * @type {import('vue').ComputedRef<number|null>}
   */
  const contactId = computed(() => currentChat.value?.meta?.sender?.id);

  /**
   * All labels available for the account
   * @type {import('vue').ComputedRef<Array>}
   */
  const accountLabels = computed(() => getters['labels/getLabels'].value);

  /**
   * Labels currently saved to the contact
   * @type {import('vue').ComputedRef<Array>}
   */
  const savedLabels = computed(() => {
    if (!contactId.value) return [];
    return store.getters['contactLabels/getContactLabels'](contactId.value);
  });

  /**
   * Labels currently active on the contact
   * @type {import('vue').ComputedRef<Array>}
   */
  const activeLabels = computed(() =>
    accountLabels.value.filter(({ title }) => savedLabels.value.includes(title))
  );

  /**
   * Labels available but not active on the contact
   * @type {import('vue').ComputedRef<Array>}
   */
  const inactiveLabels = computed(() =>
    accountLabels.value.filter(
      ({ title }) => !savedLabels.value.includes(title)
    )
  );

  /**
   * Fetch contact labels when contactId changes
   */
  watch(
    contactId,
    newContactId => {
      if (newContactId) {
        store.dispatch('contactLabels/get', newContactId);
      }
    },
    { immediate: true }
  );

  /**
   * Updates the labels for the current contact
   * @param {string[]} selectedLabels - Array of label titles to be set for the contact
   * @returns {Promise<void>}
   */
  const onUpdateLabels = async selectedLabels => {
    if (!contactId.value) return;
    await store.dispatch('contactLabels/update', {
      contactId: contactId.value,
      labels: selectedLabels,
    });
    // Also update the sender labels in the conversation store for immediate UI update
    const conversation = currentChat.value;
    if (conversation && conversation.meta?.sender) {
      conversation.meta.sender.labels = selectedLabels;
    }
  };

  /**
   * Adds a label to the current contact
   * @param {Object} value - The label object to be added
   * @param {string} value.title - The title of the label to be added
   */
  const addLabelToContact = value => {
    const result = activeLabels.value.map(item => item.title);
    result.push(value.title);
    onUpdateLabels(result);
  };

  /**
   * Removes a label from the current contact
   * @param {string} value - The title of the label to be removed
   */
  const removeLabelFromContact = value => {
    const result = activeLabels.value
      .map(label => label.title)
      .filter(label => label !== value);
    onUpdateLabels(result);
  };

  return {
    accountLabels,
    savedLabels,
    activeLabels,
    inactiveLabels,
    addLabelToContact,
    removeLabelFromContact,
    onUpdateLabels,
  };
}
