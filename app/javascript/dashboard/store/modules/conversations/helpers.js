import {
  CONVERSATION_PRIORITY_ORDER,
  MESSAGE_TYPE,
} from 'shared/constants/messages';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants.js';

export const languageCode = locale => locale?.split(/[-_]/)[0];

const BOT_SENDERS = ['agent_bot', 'captain_assistant'];
// A contact message, or a bot reply written in the contact language: both read in the agent language.
export const isContactSide = (messageType, senderType) =>
  messageType === MESSAGE_TYPE.INCOMING || BOT_SENDERS.includes(senderType);

const TRANSLATABLE_CONTENT_TYPES = [
  CONTENT_TYPES.TEXT,
  CONTENT_TYPES.INCOMING_EMAIL,
];

// Only text is translated: call bubbles, cards and forms carry fixed labels, and html mail keeps its markup.
export const isTranslatable = message =>
  isContactSide(message.message_type, message.sender?.type) &&
  TRANSLATABLE_CONTENT_TYPES.includes(message.content_type) &&
  !!message.content &&
  !message.content_attributes?.deleted &&
  !message.content_attributes?.email?.html_content?.full;

// Stored with another language, a message stays translated after the thread switched to the agent language.
export const isForeign = (message, locale) => {
  const source = message.content_attributes?.source_language;
  return !!source && languageCode(source) !== languageCode(locale);
};

export const findPendingMessageIndex = (chat, message) => {
  const { echo_id: tempMessageId } = message;
  return chat.messages.findIndex(
    m => m.id === message.id || m.id === tempMessageId
  );
};

// A cable event can land while a list or sync response is in flight, so a response can carry an
// older row than the one the store already holds. `updated_at` is a float epoch on both sides, and
// this is the same comparison UPDATE_CONVERSATION makes for out-of-order cable events.
export const isStaleConversation = (incoming, existing) =>
  Boolean(existing) && incoming.updated_at < existing.updated_at;

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

// `all` is what the dropdown sends for "no preference", and the server treats it the same way
// (`ConversationFinder#filter_by_group_type` returns early on it).
export const filterByGroupType = (shouldFilter, groupType, chatGroupType) => {
  if (!groupType || groupType === 'all') return shouldFilter;
  return groupType === chatGroupType && shouldFilter;
};

export const applyPageFilters = (conversation, filters) => {
  const {
    inboxId,
    status,
    labels = [],
    teamId,
    conversationType,
    groupType,
  } = filters;
  const {
    status: chatStatus,
    inbox_id: chatInboxId,
    labels: chatLabels = [],
    meta = {},
    first_reply_created_at: firstReplyOn,
    waiting_since: waitingSince,
    group_type: chatGroupType,
  } = conversation;
  const team = meta.team || {};
  const { id: chatTeamId } = team;

  let shouldFilter = filterByStatus(chatStatus, status);
  shouldFilter = filterByInbox(shouldFilter, inboxId, chatInboxId);
  shouldFilter = filterByTeam(shouldFilter, teamId, chatTeamId);
  shouldFilter = filterByLabel(shouldFilter, labels, chatLabels);
  shouldFilter = filterByGroupType(shouldFilter, groupType, chatGroupType);
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
/**
 * The human this conversation is assigned to, or undefined.
 *
 * `meta.assignee` is whoever holds the conversation, bot included, and `meta.assignee_type`
 * is what says which. A bot holding a conversation counts as ASSIGNED everywhere the server
 * decides: `scope :unassigned` requires `assignee_agent_bot_id` to be null too, the tab's
 * badge counts the same way, and `conversation_unassigned_manage` grants access through that
 * same scope. So this helper is not the answer to "is this unassigned" — `meta.assignee` is.
 *
 * Use it only where the question really is "which human", such as matching an agent's own id:
 * a bot's id comes from its own table and can be the same integer as an agent's.
 *
 * @param {{meta?: {assignee?: Object, assignee_type?: string}}} conversation
 * @returns {Object|undefined}
 */
export const humanAssignee = conversation => {
  const { assignee, assignee_type: assigneeType } = conversation?.meta ?? {};
  return assigneeType === 'AgentBot' ? undefined : assignee;
};

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

  // Two different questions, and the server answers them from two different columns:
  // `conversations.unassigned` (which excludes a conversation a bot holds, so whoever holds it is
  // what settles it) OR `assigned_to(user)`, which reads `assignee_id` and can only ever name a
  // human. Comparing the raw assignee's id against the agent's would match a bot that happens to
  // share the integer, since bot ids come from their own table.
  const isUnassigned = !conversation.meta.assignee;
  const isAssignedToUser = humanAssignee(conversation)?.id === currentUserId;

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
  unread: ['sortOnUnread', 'desc'],
};
const sortAscending = (valueA, valueB) => valueA - valueB;
const sortDescending = (valueA, valueB) => valueB - valueA;

const getSortOrderFunction = sortOrder =>
  sortOrder === 'asc' ? sortAscending : sortDescending;

const sortConfig = {
  sortOnLastActivityAt: (a, b, sortDirection) =>
    getSortOrderFunction(sortDirection)(a.last_activity_at, b.last_activity_at),

  sortOnCreatedAt: (a, b, sortDirection) =>
    getSortOrderFunction(sortDirection)(a.created_at, b.created_at) ||
    getSortOrderFunction(sortDirection)(a.id, b.id),

  sortOnPriority: (a, b, sortDirection) => {
    const DEFAULT_FOR_NULL = sortDirection === 'asc' ? 5 : 0;

    const p1 = CONVERSATION_PRIORITY_ORDER[a.priority] || DEFAULT_FOR_NULL;
    const p2 = CONVERSATION_PRIORITY_ORDER[b.priority] || DEFAULT_FOR_NULL;
    const priorityDiff = getSortOrderFunction(sortDirection)(p1, p2);
    if (priorityDiff !== 0) return priorityDiff;

    return sortDescending(a.last_activity_at, b.last_activity_at);
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
        return sortAscending(a.created_at, b.created_at);
      }
      return a.waiting_since ? -1 : 1;
    }

    return sortFunc(a.waiting_since, b.waiting_since);
  },

  sortOnUnread: (a, b) => {
    const unreadCountDiff = (b.unread_count || 0) - (a.unread_count || 0);
    if (unreadCountDiff !== 0) return unreadCountDiff;

    return (b.last_activity_at || 0) - (a.last_activity_at || 0);
  },
};

// Pinned conversations lead the list on every sort option, most recently pinned first, mirroring what the
// API already returns. `pinnedAtById` maps a conversation id to the epoch seconds it was pinned at.
export const sortComparator = (a, b, sortKey, pinnedAtById = {}) => {
  const pinnedAtA = pinnedAtById[a.id];
  const pinnedAtB = pinnedAtById[b.id];

  if (pinnedAtA && pinnedAtB) return pinnedAtB - pinnedAtA;
  if (pinnedAtA) return -1;
  if (pinnedAtB) return 1;

  const [sortMethod, sortDirection] =
    SORT_OPTIONS[sortKey] || SORT_OPTIONS.last_activity_at_desc;
  return sortConfig[sortMethod](a, b, sortDirection);
};
