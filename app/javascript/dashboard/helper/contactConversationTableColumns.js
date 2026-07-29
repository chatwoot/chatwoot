import {
  buildCustomColumns,
  isCustomColumnKey,
  attributeKeyFromColumn,
} from 'dashboard/helper/contactTableColumns';

export const DEFAULT_CONTACT_CONVERSATION_COLUMNS = Object.freeze([
  'id',
  'status',
  'inbox',
  'assignee',
  'priority',
  'last_activity_at',
  'created_at',
]);

export const STANDARD_CONTACT_CONVERSATION_COLUMNS = Object.freeze([
  {
    key: 'id',
    labelKey: 'ID',
    sortable: false,
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
    // Contacts table uses sortKey `custom:key`; conversation API wants same
    sortKey: col.key,
  }));
  return [...STANDARD_CONTACT_CONVERSATION_COLUMNS, ...custom];
};

export { isCustomColumnKey, attributeKeyFromColumn };
