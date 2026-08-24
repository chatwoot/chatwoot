import { reactive } from 'vue';
import { useStore } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/inbox/conversation';

export function useKanbanBoard() {
  const store = useStore();

  // Keyed by label title: { conversations: Array, isFetching: Boolean }
  const columns = reactive({});

  const fetchColumn = async labelTitle => {
    columns[labelTitle] = columns[labelTitle] || {
      conversations: [],
      isFetching: false,
    };
    columns[labelTitle].isFetching = true;
    try {
      const {
        data: { data },
      } = await ConversationApi.get({ labels: [labelTitle], status: 'all' });
      columns[labelTitle].conversations = data.payload;
    } finally {
      columns[labelTitle].isFetching = false;
    }
  };

  const fetchBoard = async labelTitles => {
    await Promise.all(labelTitles.map(fetchColumn));
  };

  const moveCard = async ({ conversation, fromLabel, toLabel }) => {
    if (fromLabel === toLabel) return;

    const previousLabels = conversation.labels || [];
    const nextLabels = [
      ...previousLabels.filter(label => label !== fromLabel),
      toLabel,
    ];

    try {
      await store.dispatch('conversationLabels/update', {
        conversationId: conversation.id,
        labels: nextLabels,
      });
      conversation.labels = nextLabels;
    } catch (error) {
      // Revert the optimistic move so the board matches the server state.
      await Promise.all([fetchColumn(fromLabel), fetchColumn(toLabel)]);
      throw error;
    }
  };

  return { columns, fetchBoard, fetchColumn, moveCard };
}
