import { CONVERSATION_PRIORITY_ORDER } from 'shared/constants/messages';

/**
 * Appends a message to a chat's message list, keeping the list ordered by
 * `created_at`. Messages are usually delivered in order, but a message can
 * arrive late (e.g. a backlogged websocket broadcast for a note written by
 * another agent while the conversation was assigned to them) after messages
 * created after it were already appended (e.g. the current agent's own
 * optimistically-added message). Sorting on insert avoids showing messages
 * out of chronological order until the page is reloaded.
 */
export const pushMessageInOrder = (chat, message) => {
  chat.messages.push(message);
  chat.messages.sort((a, b) => a.created_at - b.created_at);
};

/**
 * Resolves where an incoming message belongs in a chat's message list.
 *
 * A pending (optimistically added) message and its "real" counterpart can
 * briefly coexist: the real message may arrive over websocket before the
 * pending send request resolves, leaving a stale pending entry (matched by
 * `echo_id`) alongside it. Returning both indices lets the caller update the
 * correct entry and drop the stale one instead of ending up with duplicates.
 *
 * @returns {{ index: number, staleIndex: number }} `index` is where the
 * message should be written (-1 if it should be appended). `staleIndex` is
 * a leftover pending entry to remove, if any (-1 if none).
 */
export const findPendingMessageIndex = (chat, message) => {
  const { echo_id: tempMessageId } = message;
  const realIndex = chat.messages.findIndex(m => m.id === message.id);
  const pendingIndex =
    tempMessageId != null
      ? chat.messages.findIndex(m => m.id === tempMessageId)
      : -1;

  if (realIndex !== -1) {
    const staleIndex = pendingIndex !== realIndex ? pendingIndex : -1;
    return { index: realIndex, staleIndex };
  }
  return { index: pendingIndex, staleIndex: -1 };
};

export const filterByStatus = (chatStatus, filterStatus) => {
  if (filterStatus === 'all') return true;
  if (filterStatus === 'open')
    return chatStatus === 'open' || chatStatus === 'resolved';
  return chatStatus === filterStatus;
};

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
  if (role === 'administrator') {
    return true;
  }

  if (role === 'agent') {
    const conversationAssignee = conversation.meta?.assignee;
    const isUnassigned = !conversationAssignee;
    const isAssignedToUser = conversationAssignee?.id === currentUserId;
    return isUnassigned || isAssignedToUser;
  }

  // Check for full conversation management permission
  if (permissions.includes('conversation_manage')) {
    return true;
  }

  const conversationAssignee = conversation.meta.assignee;
  const isUnassigned = !conversationAssignee;
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
const sortAscending = (valueA, valueB) => valueA - valueB;
const sortDescending = (valueA, valueB) => valueB - valueA;

const getSortOrderFunction = sortOrder =>
  sortOrder === 'asc' ? sortAscending : sortDescending;

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
  const [sortMethod, sortDirection] =
    SORT_OPTIONS[sortKey] || SORT_OPTIONS.last_activity_at_desc;
  return sortConfig[sortMethod](a, b, sortDirection);
};
