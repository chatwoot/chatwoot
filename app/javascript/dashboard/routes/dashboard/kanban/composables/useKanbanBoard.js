import { reactive } from 'vue';
import { useStore } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/inbox/conversation';

// Column key used for conversations where the board attribute has no value set.
export const UNASSIGNED_COLUMN_KEY = '__unassigned__';

const conditionForValue = (attributeKey, value) =>
  value === UNASSIGNED_COLUMN_KEY
    ? {
        attribute_key: attributeKey,
        filter_operator: 'is_not_present',
        values: [],
        query_operator: null,
      }
    : {
        attribute_key: attributeKey,
        filter_operator: 'equal_to',
        values: [value],
        query_operator: null,
      };

export function useKanbanBoard() {
  const store = useStore();

  // Keyed by attribute value (or UNASSIGNED_COLUMN_KEY): { conversations: Array, isFetching: Boolean }
  const columns = reactive({});

  const fetchColumn = async (attributeKey, value) => {
    columns[value] = columns[value] || {
      conversations: [],
      isFetching: false,
    };
    columns[value].isFetching = true;
    try {
      const { data } = await ConversationApi.filter({
        queryData: { payload: [conditionForValue(attributeKey, value)] },
        page: 1,
      });
      columns[value].conversations = data.payload;
    } finally {
      columns[value].isFetching = false;
    }
  };

  const fetchBoard = async (attributeKey, values) => {
    await Promise.all(values.map(value => fetchColumn(attributeKey, value)));
  };

  const moveCard = async ({
    conversation,
    attributeKey,
    fromValue,
    toValue,
  }) => {
    if (fromValue === toValue) return;

    const existingAttributes = conversation.custom_attributes || {};
    let updatedAttributes;
    if (toValue === UNASSIGNED_COLUMN_KEY) {
      const { [attributeKey]: _removed, ...rest } = existingAttributes;
      updatedAttributes = rest;
    } else {
      updatedAttributes = { ...existingAttributes, [attributeKey]: toValue };
    }

    try {
      await store.dispatch('updateCustomAttributes', {
        conversationId: conversation.id,
        customAttributes: updatedAttributes,
      });
      conversation.custom_attributes = updatedAttributes;
    } catch (error) {
      // Revert the optimistic move so the board matches the server state.
      await Promise.all([
        fetchColumn(attributeKey, fromValue),
        fetchColumn(attributeKey, toValue),
      ]);
      throw error;
    }
  };

  return { columns, fetchBoard, fetchColumn, moveCard };
}
