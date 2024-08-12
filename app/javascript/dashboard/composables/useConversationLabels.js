import { computed } from 'vue';
import { useStore, useStoreGetters } from 'dashboard/composables/store';

export function useConversationLabels() {
  const store = useStore();
  const getters = useStoreGetters();
  const currentChat = computed(() => getters.getSelectedChat.value);
  const conversationId = computed(() => currentChat.value?.id);

  const accountLabels = computed(() => getters['labels/getLabels'].value);

  const savedLabels = computed(() => {
    return store.getters['conversationLabels/getConversationLabels'](
      conversationId.value
    );
  });

  const activeLabels = computed(() =>
    accountLabels.value.filter(({ title }) => savedLabels.value.includes(title))
  );

  const inactiveLabels = computed(() =>
    accountLabels.value.filter(
      ({ title }) => !savedLabels.value.includes(title)
    )
  );

  const onUpdateLabels = async selectedLabels => {
    store.dispatch('conversationLabels/update', {
      conversationId: conversationId.value,
      labels: selectedLabels,
    });
  };

  const addLabelToConversation = value => {
    const result = activeLabels.value.map(item => item.title);
    result.push(value.title);
    onUpdateLabels(result);
  };

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
