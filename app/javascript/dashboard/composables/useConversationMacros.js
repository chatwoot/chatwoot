import { computed } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

/**
 * Composable for managing conversation macros
 * @returns {Object} An object containing methods and computed properties for conversation macros
 */
export function useConversationMacros() {
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

  const activeMacros = computed(() => getters['macros/getMacros'].value);

  const playMacroToConversation = (macroId) => {
    store.dispatch('macros/execute', {
      macroId: macroId,
      conversationIds: [conversationId.value],
      macroId,
    });
  };

  return {
    activeMacros,
    playMacroToConversation,
  };
}
