import { CONVERSATION_PRIORITY_ORDER } from 'shared/constants/messages';
import {
  isAgentBotAssigneeMeta,
  isHumanAssigneeMeta,
} from 'dashboard/helper/assigneeHelper';

export const findPendingMessageIndex = (chat, message) => {
  const { echo_id: tempMessageId } = message;
  return chat.messages.findIndex(
    m => m.id === message.id || m.id === tempMessageId
  );
};

export const filterByStatus = (chatStatus, filterStatus) =>
  filterStatus === 'all' ? true : chatStatus === filterStatus;

export const filterByInbox = (shouldFilter, inboxId, chatInboxId) => {
  const isOnInbox = Number(inboxId) === chatInboxId;
  return inboxId ? isOnInbox && shouldFilter : shouldFilter;
};

export const filterByTeam = (shouldFilter, teamId, chatTeamId) => {
  const isOnTeam = Number(teamId) === chatTeamId;
  return teamId ? isOnTeam && shouldFilter : shouldFilter;
};

export const filterByLabel = (shouldFilter, labels, chatLabels) => {
  const isOnLabel = labels.every(label => chatLabels.includes(label));
  return labels.length ? isOnLabel && shouldFilter : shouldFilter;
};
/**
 * Whether a conversation belongs on the "unassigned" assignee tab.
 * When the inbox has an active bot, bot-assigned threads count as the bot queue.
 */
export const matchesUnassignedTab = (conversation, { inboxBotId } = {}) => {
  const { assignee } = conversation.meta || {};

  if (inboxBotId) {
    return !assignee || isAgentBotAssigneeMeta(conversation.meta, inboxBotId);
  }

  return !isHumanAssigneeMeta(conversation.meta);
};

export const filterByUnattended = (
  shouldFilter,
  conversationType,
  firstReplyOn,
  waitingSince
) => {
  return conversationType === 'unattended'
    ? (!firstReplyOn || !!waitingSince) && shouldFilter
    : shouldFilter;
};

export const applyPageFilters = (conversation, filters) => {
  const { inboxId, status, labels = [], teamId, conversationType } = filters;
  const {
    status: chatStatus,
    inbox_id: chatInboxId,
    labels: chatLabels = [],
    meta = {},
    first_reply_created_at: firstReplyOn,
    waiting_since: waitingSince,
  } = conversation;
  const team = meta.team || {};
  const { id: chatTeamId } = team;

  let shouldFilter = filterByStatus(chatStatus, status);
  shouldFilter = filterByInbox(shouldFilter, inboxId, chatInboxId);
  shouldFilter = filterByTeam(shouldFilter, teamId, chatTeamId);
  shouldFilter = filterByLabel(shouldFilter, labels, chatLabels);
  shouldFilter = filterByUnattended(
    shouldFilter,
    conversationType,
    firstReplyOn,
    waitingSince
  );

  return shouldFilter;
};

/**
 * Filters conversations based on user role and permissions
 *
 * @param {Object} conversation - The conversation object to check permissions for
 * @param {string} role - The user's role (administrator, agent, etc.)
 * @param {Array<string>} permissions - List of permission strings the user has
 * @param {number|string} currentUserId - The ID of the current user
 * @returns {boolean} - Whether the user has permissions to access this conversation
 */
export const applyRoleFilter = (
  conversation,
  role,
  permissions,
  currentUserId
) => {
  // the role === "agent" check is typically not correct on it's own
  // the backend handles this by checking the custom_role_id at the user model
  // here however, the `getUserRole` returns "custom_role" if the id is present,
  // so we can check the role === "agent" directly
  if (['administrator', 'agent'].includes(role)) {
    return true;
  }

  // Check for full conversation management permission
  if (permissions.includes('conversation_manage')) {
    return true;
  }

  const conversationAssignee = conversation.meta.assignee;
  const isUnassigned = !isHumanAssigneeMeta(conversation.meta);
  const isAssignedToUser = conversationAssignee?.id === currentUserId;

  // Check unassigned management permission
  if (permissions.includes('conversation_unassigned_manage')) {
    return isUnassigned || isAssignedToUser;
  }

  // Check participating conversation management permission
  if (permissions.includes('conversation_participating_manage')) {
    return isAssignedToUser;
  }

  return false;
};

const SORT_OPTIONS = {
  last_activity_at_asc: ['sortOnLastActivityAt', 'asc'],
  last_activity_at_desc: ['sortOnLastActivityAt', 'desc'],
  created_at_asc: ['sortOnCreatedAt', 'asc'],
  created_at_desc: ['sortOnCreatedAt', 'desc'],
  priority_asc: ['sortOnPriority', 'asc'],
  priority_desc: ['sortOnPriority', 'desc'],
  waiting_since_asc: ['sortOnWaitingSince', 'asc'],
  waiting_since_desc: ['sortOnWaitingSince', 'desc'],
  priority_desc_created_at_asc: ['sortOnPriorityCreatedAt', 'desc'],
};

const CUSTOM_SORT_REGEX = /^(-?)custom:(.+)$/;

export const parseCustomConversationSort = sortKey => {
  const match = String(sortKey || '').match(CUSTOM_SORT_REGEX);
  if (!match) return null;
  return {
    direction: match[1] === '-' ? 'desc' : 'asc',
    attributeKey: match[2],
  };
};

export const isValidConversationSortKey = sortKey => {
  if (!sortKey) return false;
  if (SORT_OPTIONS[sortKey] || sortKey === 'unread') return true;
  return !!parseCustomConversationSort(sortKey);
};

const sortAscending = (valueA, valueB) => valueA - valueB;
const sortDescending = (valueA, valueB) => valueB - valueA;

const getSortOrderFunction = sortOrder =>
  sortOrder === 'asc' ? sortAscending : sortDescending;

const getCustomAttributeValue = (conversation, attributeKey) => {
  const attrs =
    conversation.custom_attributes || conversation.customAttributes || {};
  return attrs[attributeKey];
};

const compareCustomAttribute = (a, b, attributeKey, direction) => {
  const rawA = getCustomAttributeValue(a, attributeKey);
  const rawB = getCustomAttributeValue(b, attributeKey);
  const emptyA = rawA == null || rawA === '';
  const emptyB = rawB == null || rawB === '';

  if (emptyA && emptyB) {
    return getSortOrderFunction(direction)(a.created_at, b.created_at);
  }
  if (emptyA) return 1;
  if (emptyB) return -1;

  const numA = Number(String(rawA).replace(/[^0-9.-]+/g, ''));
  const numB = Number(String(rawB).replace(/[^0-9.-]+/g, ''));
  if (!Number.isNaN(numA) && !Number.isNaN(numB) && String(rawA).match(/\d/)) {
    return getSortOrderFunction(direction)(numA, numB);
  }

  const strA = String(rawA).toLowerCase();
  const strB = String(rawB).toLowerCase();
  if (strA < strB) return direction === 'asc' ? -1 : 1;
  if (strA > strB) return direction === 'asc' ? 1 : -1;
  return 0;
};

const sortConfig = {
  sortOnLastActivityAt: (a, b, sortDirection) =>
    getSortOrderFunction(sortDirection)(a.last_activity_at, b.last_activity_at),

  sortOnCreatedAt: (a, b, sortDirection) =>
    getSortOrderFunction(sortDirection)(a.created_at, b.created_at),

  sortOnPriority: (a, b, sortDirection) => {
    const DEFAULT_FOR_NULL = sortDirection === 'asc' ? 5 : 0;

    const p1 = CONVERSATION_PRIORITY_ORDER[a.priority] || DEFAULT_FOR_NULL;
    const p2 = CONVERSATION_PRIORITY_ORDER[b.priority] || DEFAULT_FOR_NULL;

    return getSortOrderFunction(sortDirection)(p1, p2);
  },

  sortOnPriorityCreatedAt: (a, b) => {
    const DEFAULT_FOR_NULL = 0;
    const p1 = CONVERSATION_PRIORITY_ORDER[a.priority] || DEFAULT_FOR_NULL;
    const p2 = CONVERSATION_PRIORITY_ORDER[b.priority] || DEFAULT_FOR_NULL;
    if (p1 !== p2) return p2 - p1;
    return a.created_at - b.created_at;
  },

  sortOnWaitingSince: (a, b, sortDirection) => {
    const sortFunc = getSortOrderFunction(sortDirection);
    if (!a.waiting_since || !b.waiting_since) {
      if (!a.waiting_since && !b.waiting_since) {
        return sortFunc(a.created_at, b.created_at);
      }
      return sortFunc(a.waiting_since ? 0 : 1, b.waiting_since ? 0 : 1);
    }

    return sortFunc(a.waiting_since, b.waiting_since);
  },
};

export const sortComparator = (a, b, sortKey) => {
  const custom = parseCustomConversationSort(sortKey);
  if (custom) {
    return compareCustomAttribute(a, b, custom.attributeKey, custom.direction);
  }

  const [sortMethod, sortDirection] =
    SORT_OPTIONS[sortKey] || SORT_OPTIONS.last_activity_at_desc;
  return sortConfig[sortMethod](a, b, sortDirection);
};
