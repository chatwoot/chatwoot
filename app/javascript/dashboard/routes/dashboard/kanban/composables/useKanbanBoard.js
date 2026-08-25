import { reactive } from 'vue';
import { useStore } from 'dashboard/composables/store';
import ConversationApi from 'dashboard/api/inbox/conversation';

// Column key used for conversations where the board attribute has no value set.
export const UNASSIGNED_COLUMN_KEY = '__unassigned__';

const attributeCondition = (attributeKey, value) =>
  value === UNASSIGNED_COLUMN_KEY
    ? {
        attribute_key: attributeKey,
        filter_operator: 'is_not_present',
        values: [],
      }
    : {
        attribute_key: attributeKey,
        filter_operator: 'equal_to',
        values: [value],
      };

// Non-admins only get to see conversations assigned to them; admins see the
// whole column. assigneeId is expected to be falsy for admins.
const buildQueryPayload = (attributeKey, value, assigneeId) => {
  const conditions = [attributeCondition(attributeKey, value)];
  if (assigneeId) {
    conditions.push({
      attribute_key: 'assignee_id',
      filter_operator: 'equal_to',
      values: [assigneeId],
    });
  }
  // Every condition but the last needs a query_operator; the API rejects one
  // present on the last condition.
  return conditions.map((condition, index) => ({
    ...condition,
    query_operator: index < conditions.length - 1 ? 'and' : null,
  }));
};

const emptyColumn = () => ({
  conversations: [],
  isFetching: false,
  isFetchingMore: false,
  page: 1,
  hasMore: false,
  totalCount: 0,
});

export function useKanbanBoard() {
  const store = useStore();

  // Keyed by attribute value (or UNASSIGNED_COLUMN_KEY).
  const columns = reactive({});

  const fetchColumn = async (
    attributeKey,
    value,
    { assigneeId, sortBy, page = 1 } = {}
  ) => {
    columns[value] = columns[value] || emptyColumn();
    const isFirstPage = page === 1;
    columns[value][isFirstPage ? 'isFetching' : 'isFetchingMore'] = true;
    try {
      const { data } = await ConversationApi.filter({
        queryData: {
          payload: buildQueryPayload(attributeKey, value, assigneeId),
        },
        page,
        sortBy,
      });
      columns[value].conversations = isFirstPage
        ? data.payload
        : [...columns[value].conversations, ...data.payload];
      columns[value].totalCount =
        data.meta?.count?.all_count ?? columns[value].conversations.length;
      columns[value].page = page;
      columns[value].hasMore =
        columns[value].conversations.length < columns[value].totalCount;
    } finally {
      columns[value][isFirstPage ? 'isFetching' : 'isFetchingMore'] = false;
    }
  };

  const fetchBoard = async (attributeKey, values, options) => {
    await Promise.all(
      values.map(value => fetchColumn(attributeKey, value, options))
    );
  };

  const fetchMore = (attributeKey, value, options) => {
    const column = columns[value];
    if (!column || column.isFetchingMore || !column.hasMore) return;
    fetchColumn(attributeKey, value, { ...options, page: column.page + 1 });
  };

  const moveCard = async ({
    conversation,
    attributeKey,
    fromValue,
    toValue,
    assigneeId,
    sortBy,
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
        fetchColumn(attributeKey, fromValue, { assigneeId, sortBy }),
        fetchColumn(attributeKey, toValue, { assigneeId, sortBy }),
      ]);
      throw error;
    }
  };

  return { columns, fetchBoard, fetchColumn, fetchMore, moveCard };
}
