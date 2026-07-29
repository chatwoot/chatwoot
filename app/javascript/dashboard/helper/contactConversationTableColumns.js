import {
  buildCustomColumns,
  isCustomColumnKey,
  attributeKeyFromColumn,
  normalizeSavedColumnKeys,
} from 'dashboard/helper/contactTableColumns';

export const HISTORY_COLUMNS_UI_SETTING =
  'contact_conversation_history_columns';

export const DEFAULT_CONTACT_CONVERSATION_COLUMNS = Object.freeze([
  'id',
  'status',
  'inbox',
  'last_message_from',
  'last_activity_at',
  'assignee',
]);

export const STANDARD_CONTACT_CONVERSATION_COLUMNS = Object.freeze([
  {
    key: 'id',
    labelKey: 'ID',
    sortable: false,
    required: true,
  },
  {
    key: 'status',
    labelKey: 'STATUS',
    sortable: false,
  },
  {
    key: 'inbox',
    labelKey: 'INBOX',
    sortable: false,
  },
  {
    key: 'assignee',
    labelKey: 'ASSIGNEE',
    sortable: false,
  },
  {
    key: 'priority',
    labelKey: 'PRIORITY',
    sortable: true,
    sortKey: 'priority',
  },
  {
    key: 'last_message_from',
    labelKey: 'LAST_MESSAGE_FROM',
    sortable: true,
    sortKey: 'last_message_from',
  },
  {
    key: 'last_message',
    labelKey: 'LAST_MESSAGE',
    sortable: false,
  },
  {
    key: 'waiting_since',
    labelKey: 'WAITING_SINCE',
    sortable: true,
    sortKey: 'waiting_since',
  },
  {
    key: 'unread_count',
    labelKey: 'UNREAD',
    sortable: false,
  },
  {
    key: 'last_activity_at',
    labelKey: 'LAST_ACTIVITY',
    sortable: true,
    sortKey: 'last_activity_at',
  },
  {
    key: 'created_at',
    labelKey: 'CREATED_AT',
    sortable: true,
    sortKey: 'created_at',
  },
]);

export const buildConversationHistoryColumns = attributeDefinitions => {
  const custom = buildCustomColumns(attributeDefinitions).map(col => ({
    ...col,
    sortKey: col.key,
  }));
  return [...STANDARD_CONTACT_CONVERSATION_COLUMNS, ...custom];
};

export const resolveHistoryVisibleColumns = (savedKeys, availableKeys) => {
  const available = new Set(availableKeys);
  const defaults = DEFAULT_CONTACT_CONVERSATION_COLUMNS.filter(key =>
    available.has(key)
  );
  const cleaned = normalizeSavedColumnKeys(savedKeys).filter(key =>
    available.has(key)
  );

  if (!cleaned.length) return defaults;

  // Keep id pinned first
  const withoutId = cleaned.filter(key => key !== 'id');
  if (available.has('id')) {
    return ['id', ...withoutId];
  }
  return withoutId;
};

/** Last non-activity message from conversation payload (camel or snake). */
export const getLastNonActivityMessage = conversation => {
  if (!conversation) return null;
  return (
    conversation.lastNonActivityMessage ||
    conversation.last_non_activity_message ||
    (Array.isArray(conversation.messages) ? conversation.messages[0] : null)
  );
};

/**
 * Who sent the last non-activity message.
 * @returns {'contact'|'agent'|'bot'|'template'|null}
 */
export const resolveLastMessageFrom = conversation => {
  const msg = getLastNonActivityMessage(conversation);
  if (!msg) return null;

  const type = msg.messageType ?? msg.message_type;
  if (type === 0 || type === 'incoming') return 'contact';
  if (type === 3 || type === 'template') return 'template';
  if (type === 1 || type === 'outgoing') {
    const sender = msg.sender || {};
    if (sender.type === 'agent_bot') return 'bot';
    return 'agent';
  }
  return null;
};

/** Rank for sorting: contact < agent < bot < template < unknown */
export const lastMessageFromRank = conversation => {
  const from = resolveLastMessageFrom(conversation);
  const ranks = { contact: 0, agent: 1, bot: 2, template: 3 };
  return from == null ? 99 : (ranks[from] ?? 99);
};

export { isCustomColumnKey, attributeKeyFromColumn };
