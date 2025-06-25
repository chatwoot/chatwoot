import { computed } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

/**
 * Composable for managing conversation labels
 * @returns {Object} An object containing methods and computed properties for conversation labels
 */
export function useConversationLabels() {
  const store = useStore();
  const getters = useStoreGetters();

  /**
   * The currently selected chat
   * @type {import('vue').ComputedRef<Object>}
   */
  const currentChat = computed(() => getters.getSelectedChat.value);

  /**
   * The ID of the current conversation
   * @type {import('vue').ComputedRef<number|null>}
   */
  const conversationId = computed(() => currentChat.value?.id);

  /**
   * All labels available for the account
   * @type {import('vue').ComputedRef<Array>}
   */
  const accountLabels = computed(() => getters['labels/getLabels'].value);

  /**
   * Labels currently saved to the conversation
   * @type {import('vue').ComputedRef<Array>}
   */
  const savedLabels = computed(() => {
    return store.getters['conversationLabels/getConversationLabels'](
      conversationId.value
    );
  });

  /**
   * Labels currently active on the conversation
   * @type {import('vue').ComputedRef<Array>}
   */
  const activeLabels = computed(() =>
    accountLabels.value.filter(({ title }) => savedLabels.value.includes(title))
  );

  /**
   * Labels available but not active on the conversation
   * @type {import('vue').ComputedRef<Array>}
   */
  const inactiveLabels = computed(() =>
    accountLabels.value.filter(
      ({ title }) => !savedLabels.value.includes(title)
    )
  );

  /**
   * Updates the labels for the current conversation
   * @param {string[]} selectedLabels - Array of label titles to be set for the conversation
   * @returns {Promise<void>}
   */
  const onUpdateLabels = async selectedLabels => {
    await store.dispatch('conversationLabels/update', {
      conversationId: conversationId.value,
      labels: selectedLabels,
    });
  };

  /**
   * Adds a label to the current conversation
   * @param {Object} value - The label object to be added
   * @param {string} value.title - The title of the label to be added
   */
  const addLabelToConversation = value => {
    const result = activeLabels.value.map(item => item.title);
    result.push(value.title);
    onUpdateLabels(result);
  };

  /**
   * Removes a label from the current conversation
   * @param {string} value - The title of the label to be removed
   */
  const removeLabelFromConversation = value => {
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
    addLabelToConversation,
    removeLabelFromConversation,
    onUpdateLabels,
  };
}
