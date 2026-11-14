import types from '../../mutation-types';
import { rethrowWithResponse } from 'dashboard/store/utils/api';
import ConversationApi from '../../../api/inbox/conversation';
import MessageApi from '../../../api/inbox/message';
import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';
import { createPendingMessage } from 'dashboard/helper/commons';
import { isStaleConversation } from './helpers';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import filterQueryGenerator, {
  withTimestampTimezone,
} from 'dashboard/helper/filterQueryGenerator';
import {
  buildConversationList,
  highestMessageId,
  isOnMentionsView,
  isOnParticipatingView,
  isOnUnattendedView,
  isOnFoldersView,
} from './helpers/actionHelpers';
import messageReadActions from './actions/messageReadActions';
import messageTranslateActions from './actions/messageTranslateActions';
import * as Sentry from '@sentry/vue';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import {
  handleVoiceCallCreated,
  handleVoiceCallUpdated,
  syncConversationCallVisibility,
} from 'dashboard/helper/voice';

// Page size MessageFinder uses when walking backwards through a conversation.
const MESSAGES_PER_PAGE = 20;

const pendingHistoryRequests = new Map();

const TERMINAL_CONTACT_INFO_REQUEST_STATES = ['shared', 'identity_conflict'];

const contactInfoSourceId = message =>
  message.conversation?.contact_inbox?.source_id;

const hasContactInfoSource = (conversation, sourceId) => {
  return (conversation.messages || []).some(message => {
    return contactInfoSourceId(message) === sourceId;
  });
};

const contactInfoRefreshConversationIds = (state, message) => {
  const conversationIds = new Set([message.conversation_id].filter(Boolean));
  const sourceId = contactInfoSourceId(message);
  if (!sourceId) return [...conversationIds];

  (state.allConversations || []).forEach(conversation => {
    if (hasContactInfoSource(conversation, sourceId)) {
      conversationIds.add(conversation.id);
    }
  });

  return [...conversationIds];
};

export const hasMessageFailedWithExternalError = pendingMessage => {
  // This helper is used to check if the message has failed with an external error.
  // We have two cases
  // 1. Messages that fail from the UI itself (due to large attachments or a failed network):
  //    In this case, the message will have a status of failed but no external error. So we need to create that message again
  // 2. Messages sent from Chatwoot but failed to deliver to the customer for some reason (user blocking or client system down):
  //    In this case, the message will have a status of failed and an external error. So we need to retry that message
  const { content_attributes: contentAttributes, status } = pendingMessage;
  const externalError = contentAttributes?.external_error ?? '';
  return status === MESSAGE_STATUS.FAILED && externalError !== '';
};

// The getter behind each assignee tab is the same predicate the list on screen uses, so what it
// returns is exactly what the agent is looking at. Saved filters and folders narrow the list with
// a rule of their own and have no assigneeType, so they fall out here.
const TAB_GETTERS = {
  me: 'getMineChats',
  unassigned: 'getUnAssignedChats',
  all: 'getAllStatusChats',
};

// Mentions and participating do carry an assigneeType, but the server narrows those lists by a
// membership the store cannot reproduce, so what is on screen there is not the tab a reconciliation
// would judge it against.
const UNRECONCILABLE_VIEWS = [
  wootConstants.CONVERSATION_TYPE.MENTION,
  wootConstants.CONVERSATION_TYPE.PARTICIPATING,
];

// The trigger fires from a watcher, which can fire again while the request is still out.
const tabsBeingReconciled = new Set();
const conversationListRequest = useAbortableRequest();

// actions
// Mirrors `MessageFinder::CATCH_UP_LIMIT`: the number of rows one `after` call answers, and
// therefore what tells a full window apart from the last one. The page cap is a stop, not a
// budget -- 2000 rows is far past any real reconnect, and a server that kept answering full
// windows would otherwise loop here for ever.
const CATCH_UP_PAGE_SIZE = 100;
const MAX_CATCH_UP_PAGES = 20;

const actions = {
  getConversation: async ({ commit, dispatch }, conversationId) => {
    try {
      const response = await ConversationApi.show(conversationId);
      // API refreshes can run in the background after reconnecting. Use the
      // list merge to preserve local message state without moving the agent's
      // scroll position or marking messages as read.
      commit(types.SET_ALL_CONVERSATION, [response.data]);
      commit(`contacts/${types.SET_CONTACT_ITEM}`, response.data.meta.sender);
      dispatch('conversationLabels/setConversationLabel', {
        id: response.data.id,
        data: response.data.labels,
      });
    } catch (error) {
      // Ignore error
    }
  },

  fetchAllConversations: async (
    { commit, state, dispatch },
    { replaceExisting = false } = {}
  ) => {
    return conversationListRequest.run(async signal => {
      const params = state.conversationFilters;
      const countRequest = await dispatch(
        'conversationStats/onListRequestStarted',
        params
      );
      if (signal.aborted) return;
      commit(types.SET_LIST_LOADING_STATUS);
      try {
        const {
          data: { data },
        } = await ConversationApi.get(params, { signal });

        if (signal.aborted) return;

        buildConversationList(
          { commit, dispatch },
          params,
          data,
          params.assigneeType,
          { replaceExisting, countRequest }
        );
      } catch (error) {
        if (!signal.aborted) {
          commit(types.CLEAR_LIST_LOADING_STATUS);
        }
      }
    });
  },

  fetchFilteredConversations: async ({ commit, dispatch, state }, params) => {
    return conversationListRequest.run(async signal => {
      const {
        replaceExisting = false,
        sortBy = state.chatSortFilter,
        ...requestParams
      } = params;
      // The contact scope pins its own order to match the in-thread navigation.
      const filterRequestParams = {
        ...requestParams,
        sortBy: state.appliedFiltersSortBy || sortBy,
      };
      const countRequest = await dispatch(
        'conversationStats/onListRequestStarted',
        filterRequestParams
      );
      if (signal.aborted) return;
      commit(types.SET_LIST_LOADING_STATUS);
      try {
        const { data } = await ConversationApi.filter(filterRequestParams, {
          signal,
        });

        if (signal.aborted) return;

        buildConversationList(
          { commit, dispatch },
          filterRequestParams,
          data,
          'appliedFilters',
          { replaceExisting, countRequest }
        );
      } catch (error) {
        if (signal.aborted) return;

        commit(types.CLEAR_LIST_LOADING_STATUS);
        throw error;
      }
    });
  },

  // Puts a tab back in sync with the server. The store is a cache nothing invalidates:
  // SET_ALL_CONVERSATION only adds or replaces, and a conversation that leaves a tab stops being
  // sent to it, so one missed cable event leaves a copy on the list forever and the copies pile up.
  //
  // Refreshes rather than evicts, because `allConversations` is shared by every tab: a conversation
  // that left "unassigned" by gaining an assignee still belongs to "all", and very likely to
  // someone's "mine". Fresh data takes it off this tab and keeps it on the others. Only what the
  // server does not return at all is removed, which means deleted or no longer permitted.
  //
  // Only the conversations that were on screen when the request went out can be judged by its
  // answer, so the candidates are snapshotted here and both the question and the verdict are
  // scoped to that list. A conversation that arrives over the cable mid-flight is not in the
  // snapshot and is therefore left alone, rather than read as missing from a reply that was
  // never about it.
  //
  // Returns what it removed, so the caller can drop the same conversations from anything keyed
  // by them.
  reconcileConversationTab: async ({ commit, getters, state }, filters) => {
    const tabGetter = TAB_GETTERS[filters.assigneeType];
    if (!tabGetter || UNRECONCILABLE_VIEWS.includes(filters.conversationType)) {
      return [];
    }
    if (tabsBeingReconciled.has(filters.assigneeType)) return [];

    tabsBeingReconciled.add(filters.assigneeType);
    try {
      const candidates = getters[tabGetter](filters).map(c => ({
        id: c.id,
        inboxId: c.inbox_id,
      }));
      if (!candidates.length) return [];

      const {
        data: { payload },
      } = await ConversationApi.sync(candidates.map(c => c.id));

      // A cable event can beat this response home, and SET_ALL_CONVERSATION replaces without
      // looking at timestamps, so an older row is dropped here rather than written over a newer
      // one. Regressing a status or an assignee would also hide the conversation with no way back:
      // a list shorter than its badge is not a contradiction anything watches for.
      const applicable = payload.filter(
        c => !isStaleConversation(c, getters.getConversationById(c.id))
      );
      // The open conversation keeps its messages and attachments through this mutation's own
      // selected-chat branch, so a refresh never empties the panel under the agent.
      if (applicable.length) commit(types.SET_ALL_CONVERSATION, applicable);

      const stillThere = new Set(payload.map(c => c.id));
      const removed = candidates.filter(c => !stillThere.has(c.id));
      if (removed.length) {
        commit(
          types.REMOVE_CONVERSATIONS,
          removed.map(c => c.id)
        );
      }
      // The panel is showing a conversation the server just refused to serve. Announced rather
      // than acted on here, because the store has no router, and announced from here rather than
      // left to each caller, because it is a fact about the removal and not about who asked.
      if (removed.some(c => c.id === state.selectedChatId)) {
        emitter.emit(BUS_EVENTS.OPEN_CONVERSATION_GONE);
      }
      return removed;
    } catch (error) {
      return [];
    } finally {
      tabsBeingReconciled.delete(filters.assigneeType);
    }
  },

  emptyAllConversations({ commit }) {
    commit(types.EMPTY_ALL_CONVERSATION);
  },

  clearSelectedState({ commit }) {
    commit(types.CLEAR_CURRENT_CHAT_WINDOW);
  },

  fetchPreviousMessages: ({ commit, dispatch }, data) => {
    const requestKey = JSON.stringify([
      MessageApi.url,
      data.conversationId,
      data.before,
      data.after,
    ]);
    if (pendingHistoryRequests.has(requestKey)) {
      return pendingHistoryRequests.get(requestKey);
    }

    const request = MessageApi.getPreviousMessages(data)
      .then(({ data: { meta, payload } }) => {
        commit(`conversationMetadata/${types.SET_CONVERSATION_METADATA}`, {
          id: data.conversationId,
          data: meta,
        });
        commit(types.SET_PREVIOUS_CONVERSATIONS, {
          id: data.conversationId,
          data: payload,
        });
        dispatch('autoTranslateMessages', data.conversationId);
        // A short backward page means the start is reached; `after` requests only prove it when empty.
        const hasReachedFirstMessage = data.after
          ? !payload.length
          : payload.length < MESSAGES_PER_PAGE;
        if (hasReachedFirstMessage) {
          commit(types.SET_ALL_MESSAGES_LOADED, data.conversationId);
        }
      })
      .finally(() => pendingHistoryRequests.delete(requestKey));

    pendingHistoryRequests.set(requestKey, request);
    return request;
  },

  // Asks the provider for the page before this thread's oldest message. Nothing comes
  // back here: the phone answers on the webhook minutes later, or never, and the rows
  // arrive through the same cable push live traffic uses.
  syncHistory: async (_, conversationId) => {
    await ConversationApi.syncHistory(conversationId);
  },

  fetchAllAttachments: async ({ commit }, conversationId) => {
    let attachments = [];

    try {
      const { data } = await ConversationApi.getAllAttachments(conversationId);
      attachments = data.payload;
    } catch (error) {
      // in case of error, log the error and continue
      Sentry.setContext('Conversation', {
        id: conversationId,
      });
      Sentry.captureException(error);
    } finally {
      // we run the commit even if the request fails
      // this ensures that the `attachment` variable is always present on chat
      commit(types.SET_ALL_ATTACHMENTS, {
        id: conversationId,
        data: attachments,
      });
    }
  },

  syncActiveConversationMessages: async (
    { commit, state, dispatch },
    { conversationId }
  ) => {
    const { allConversations, syncConversationsMessages } = state;
    const selectedChat = allConversations.find(
      conversation => conversation.id === conversationId
    );
    if (!selectedChat) return;
    try {
      const { messages } = selectedChat;
      // The server answers a bounded window per call, so an agent who was away long enough
      // to miss more than one of them used to be handed the first window and told the
      // catch-up was over: the cursor was cleared and nothing fetched the rest until the
      // conversation was opened again. Walk the windows instead, each one starting above
      // the highest id the last one carried.
      let cursor = syncConversationsMessages[conversationId];
      let meta;
      let payload = [];
      for (let page = 0; page < MAX_CATCH_UP_PAGES; page += 1) {
        // eslint-disable-next-line no-await-in-loop
        const { data } = await MessageApi.getPreviousMessages({
          conversationId,
          after: cursor,
        });
        meta = data.meta;
        payload = payload.concat(data.payload);
        // A short window is the last one. A full window that carried nothing above the
        // cursor would repeat itself for ever, so it ends the walk too.
        const next = highestMessageId(data.payload);
        if (data.payload.length < CATCH_UP_PAGE_SIZE || !(next > cursor)) break;

        cursor = next;
      }
      commit(`conversationMetadata/${types.SET_CONVERSATION_METADATA}`, {
        id: conversationId,
        data: meta,
      });
      // Find the messages that are not already present in the store
      const missingMessages = payload.filter(
        message => !messages.find(item => item.id === message.id)
      );
      selectedChat.messages.push(...missingMessages);
      // Sort the messages by created_at
      const sortedMessages = selectedChat.messages.sort((a, b) => {
        return new Date(a.created_at) - new Date(b.created_at);
      });
      commit(types.SET_MISSING_MESSAGES, {
        id: conversationId,
        data: sortedMessages,
      });
      commit(types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION, {
        conversationId,
        messageId: null,
      });
      dispatch('autoTranslateMessages', conversationId);
      dispatch('markMessagesRead', { id: conversationId }, { root: true });
    } catch (error) {
      // Handle error
    }
  },

  setConversationLastMessageId: async (
    { commit, state },
    { conversationId }
  ) => {
    const { allConversations } = state;
    const selectedChat = allConversations.find(
      conversation => conversation.id === conversationId
    );
    if (!selectedChat) return;
    const { messages } = selectedChat;
    // The highest id, not the last one in the list: the list is sorted by time, and the
    // catch-up asks for what was written after this id. A backdated row -- a history import
    // stamps `created_at` from when the message was sent and takes its id from the INSERT --
    // sits late in the sequence and early in the list, so taking the newest by time set the
    // cursor above rows the client never received, and nothing asked for them again.
    const cursor = highestMessageId(messages);
    if (cursor === undefined) return;
    commit(types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION, {
      conversationId,
      messageId: cursor,
    });
  },

  async setActiveChat({ commit, dispatch }, { data, after }) {
    commit(types.SET_CURRENT_CHAT_WINDOW, data);
    if (data.dataFetched === undefined) {
      // Reset only when refetching — a re-activated short conversation has no scroll to earn it back.
      commit(types.CLEAR_ALL_MESSAGES_LOADED, data.id);
      try {
        await dispatch('fetchPreviousMessages', {
          after,
          // A conversation with no messages at all seeds an empty array.
          // Without the cursor the finder returns the latest page instead, so
          // the fetch still resolves and SET_CHAT_DATA_FETCHED runs — reading
          // `.id` off `undefined` here used to throw and leave the chat stuck
          // with `dataFetched` unset, which also blocks scroll pagination.
          before: data.messages[0]?.id,
          conversationId: data.id,
        });
        commit(types.SET_CHAT_DATA_FETCHED, data.id);
      } catch (error) {
        // Ignore error
      }
    }
    ConversationApi.presenceSubscribe(data.id)?.catch(() => {});
  },

  // Owns both the optimistic write and its rollback. Callers used to commit the
  // new assignee themselves and nobody ever undid it, so a rejected assignment
  // (an inbox with `prevent_assignment_takeover` answers 409) left the agent
  // looking at their own name and believing they owned the conversation.
  assignAgent: async (
    { commit, dispatch, getters },
    { conversationId, assignee, assigneeType }
  ) => {
    const previousChat = getters.getConversationById(conversationId);
    const previousAssignee = previousChat?.meta?.assignee ?? null;
    const previousAssigneeType = previousChat?.meta?.assignee_type ?? null;

    commit(types.ASSIGN_AGENT, { conversationId, assignee, assigneeType });

    try {
      const response = await ConversationApi.assignAgent({
        conversationId,
        agentId: assignee?.id ?? null,
        assigneeType,
      });
      commit(types.ASSIGN_AGENT, {
        conversationId,
        assignee: response.data,
        assigneeType,
      });
    } catch (error) {
      commit(types.ASSIGN_AGENT, {
        conversationId,
        assignee: previousAssignee,
        assigneeType: previousAssigneeType,
      });
      // The rollback restores what this client last knew, and during a
      // concurrent claim that snapshot is exactly what went stale: the server
      // handed the conversation to someone else while the request was in
      // flight, so the local copy is either the wrong agent or nobody. Re-read
      // it so the field ends up on the real owner.
      if (error?.response?.status === 409) {
        dispatch('getConversation', conversationId);
      }
      throw error;
    }
  },

  // Owns the optimistic write and its rollback for the same reason assignAgent
  // does. Picking a team that excludes the current assignee moves the assignee
  // too (`ensure_assignee_is_from_team`), so a protected inbox answers 409 and
  // the team must not stay changed on screen.
  assignTeam: async (
    { commit, dispatch, getters },
    { conversationId, team }
  ) => {
    const previousTeam =
      getters.getConversationById(conversationId)?.meta?.team ?? null;

    commit(types.ASSIGN_TEAM, { team: team ?? null, conversationId });

    try {
      const response = await ConversationApi.assignTeam({
        conversationId,
        teamId: team?.id ?? 0,
      });
      commit(types.ASSIGN_TEAM, { team: response.data, conversationId });
    } catch (error) {
      commit(types.ASSIGN_TEAM, { team: previousTeam, conversationId });
      if (error?.response?.status === 409) {
        dispatch('getConversation', conversationId);
      }
      throw error;
    }
  },

  toggleStatus: async (
    { commit, dispatch },
    { conversationId, status, snoozedUntil = null, customAttributes = null }
  ) => {
    try {
      // Update custom attributes first if provided
      if (customAttributes) {
        await ConversationApi.updateCustomAttributes({
          conversationId,
          customAttributes,
        });
        commit(types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES, {
          conversationId,
          customAttributes,
        });
      }

      const {
        data: {
          payload: {
            current_status: updatedStatus,
            snoozed_until: updatedSnoozedUntil,
          } = {},
        } = {},
      } = await ConversationApi.toggleStatus({
        conversationId,
        status,
        snoozedUntil,
      });
      commit(types.CHANGE_CONVERSATION_STATUS, {
        conversationId,
        status: updatedStatus,
        snoozedUntil: updatedSnoozedUntil,
      });
    } catch (error) {
      // Reopening self-assigns the agent, so a protected inbox can refuse the
      // whole request. Swallowing that left the caller announcing a status
      // change that never happened.
      if (error?.response?.status === 409) {
        dispatch('getConversation', conversationId);
      }
      throw error;
    }
  },

  createPendingMessageAndSend: async ({ dispatch }, data) => {
    const pendingMessage = createPendingMessage(data);
    dispatch('sendMessageWithData', pendingMessage);
  },

  sendMessageWithData: async ({ commit }, pendingMessage) => {
    const { conversation_id: conversationId, id } = pendingMessage;
    try {
      commit(types.ADD_MESSAGE, {
        ...pendingMessage,
        status: MESSAGE_STATUS.PROGRESS,
      });
      const response = hasMessageFailedWithExternalError(pendingMessage)
        ? await MessageApi.retry(conversationId, id)
        : await MessageApi.create(pendingMessage);
      commit(types.ADD_MESSAGE, {
        ...response.data,
        status: MESSAGE_STATUS.SENT,
      });
      commit(types.ADD_CONVERSATION_ATTACHMENTS, {
        ...response.data,
        status: MESSAGE_STATUS.SENT,
      });
    } catch (error) {
      const errorMessage = error.response
        ? error.response.data.error
        : undefined;
      commit(types.ADD_MESSAGE, {
        ...pendingMessage,
        meta: {
          error: errorMessage,
        },
        status: MESSAGE_STATUS.FAILED,
      });
      throw error;
    }
  },

  getContactInfoRequestAvailability: async (_, { conversationId, signal }) => {
    const { data } = await ConversationApi.getContactInfoRequestAvailability(
      conversationId,
      {
        signal,
      }
    );
    return data;
  },

  requestContactInfo: async ({ commit }, conversationId) => {
    const { data } = await ConversationApi.requestContactInfo(conversationId);
    commit(types.ADD_MESSAGE, data);
    return data;
  },

  addMessage({ commit, dispatch, rootGetters }, message) {
    commit(types.ADD_MESSAGE, message);
    if (message.message_type === MESSAGE_TYPE.INCOMING) {
      commit(types.SET_CONVERSATION_CAN_REPLY, {
        conversationId: message.conversation_id,
        canReply: true,
      });
      commit(types.ADD_CONVERSATION_ATTACHMENTS, message);
      dispatch('autoTranslateMessages', message.conversation_id);
    }
    handleVoiceCallCreated(
      message,
      rootGetters?.getCurrentUserID,
      rootGetters?.getCurrentUserAvailability
    );
  },

  updateMessage({ commit, dispatch, rootGetters, state }, message) {
    commit(types.ADD_MESSAGE, message);

    const contactInfoRequest =
      message.content_attributes?.whatsapp_contact_info;
    const isTerminalContactInfoRequest =
      contactInfoRequest?.type === 'request' &&
      (message.status === MESSAGE_STATUS.FAILED ||
        TERMINAL_CONTACT_INFO_REQUEST_STATES.includes(
          contactInfoRequest.state
        ));
    if (isTerminalContactInfoRequest) {
      contactInfoRefreshConversationIds(state, message).forEach(
        conversationId => {
          dispatch('getConversation', conversationId);
        }
      );
    }

    handleVoiceCallUpdated(
      commit,
      message,
      rootGetters?.getCurrentUserID,
      rootGetters?.getCurrentUserAvailability
    );
  },

  deleteMessage: async function deleteLabels(
    { commit },
    { conversationId, messageId }
  ) {
    try {
      const { data } = await MessageApi.delete(conversationId, messageId);
      commit(types.ADD_MESSAGE, data);
      commit(types.DELETE_CONVERSATION_ATTACHMENTS, data);
    } catch (error) {
      throw new Error(error);
    }
  },

  toggleMessageReaction: function toggleMessageReaction(
    _context,
    { conversationId, messageId, emoji, echoId }
  ) {
    // The optimistic Message is dispatched to the store by the caller.
    // Backend echoes back the same echo_id via ActionCable MESSAGE_CREATED, and
    // findPendingMessageIndex in the ADD_MESSAGE mutation swaps the fake for
    // the real one. Returning the promise lets callers reconcile if the cable
    // echo is delayed/missing.
    return MessageApi.toggleReaction(conversationId, messageId, emoji, echoId);
  },

  editMessage: async function editMessage(
    { commit },
    { conversationId, messageId, content }
  ) {
    try {
      const { data } = await MessageApi.editContent(
        conversationId,
        messageId,
        content
      );
      commit(types.ADD_MESSAGE, data);
      return data;
    } catch (error) {
      throw new Error(error);
    }
  },

  deleteConversation: async ({ commit, dispatch }, conversationId) => {
    try {
      await ConversationApi.delete(conversationId);
      commit(types.DELETE_CONVERSATION, conversationId);
      dispatch('conversationStats/get');
    } catch (error) {
      throw new Error(error);
    }
  },

  addConversation({ commit, state, dispatch, rootState }, conversation) {
    const { currentInbox, appliedFilters } = state;
    const {
      inbox_id: inboxId,
      meta: { sender },
    } = conversation;
    const hasAppliedFilters = !!appliedFilters.length;
    const isMatchingInboxFilter =
      !currentInbox || Number(currentInbox) === inboxId;
    if (
      !hasAppliedFilters &&
      !isOnFoldersView(rootState) &&
      !isOnMentionsView(rootState) &&
      !isOnParticipatingView(rootState) &&
      !isOnUnattendedView(rootState) &&
      isMatchingInboxFilter
    ) {
      commit(types.ADD_CONVERSATION, conversation);
      dispatch('contacts/setContact', sender);
    }
  },

  addMentions({ dispatch, rootState }, conversation) {
    if (isOnMentionsView(rootState)) {
      dispatch('updateConversation', conversation);
    }
  },

  addUnattended({ dispatch, rootState }, conversation) {
    if (isOnUnattendedView(rootState)) {
      dispatch('updateConversation', conversation);
    }
  },

  updateConversation({ commit, dispatch, rootGetters }, conversation) {
    const sender = conversation.meta?.sender;

    commit(types.UPDATE_CONVERSATION, conversation);
    syncConversationCallVisibility(conversation, rootGetters?.getCurrentUserID);
    // The contact language can change after a message arrived; the action skips anything already handled.
    dispatch('autoTranslateMessages', conversation.id);

    dispatch('conversationLabels/setConversationLabel', {
      id: conversation.id,
      data: conversation.labels,
    });

    if (sender) dispatch('contacts/setContact', sender);
  },

  updateConversationLastActivity(
    { commit },
    { conversationId, lastActivityAt }
  ) {
    commit(types.UPDATE_CONVERSATION_LAST_ACTIVITY, {
      lastActivityAt,
      conversationId,
    });
  },

  setChatStatusFilter({ commit }, data) {
    commit(types.CHANGE_CHAT_STATUS_FILTER, data);
  },

  setChatSortFilter({ commit }, data) {
    commit(types.CHANGE_CHAT_SORT_FILTER, data);
  },

  setChatGroupTypeFilter({ commit }, data) {
    commit(types.CHANGE_CHAT_GROUP_TYPE_FILTER, data);
  },

  updateAssignee({ commit }, data) {
    commit(types.UPDATE_ASSIGNEE, data);
  },

  updateConversationContact({ commit }, data) {
    if (data.id) {
      commit(`contacts/${types.SET_CONTACT_ITEM}`, data);
    }
    commit(types.UPDATE_CONVERSATION_CONTACT, data);
  },

  handleScheduledMessageCreated({ dispatch }, scheduledMessage) {
    dispatch('scheduledMessages/upsertFromEvent', scheduledMessage);
  },

  handleScheduledMessageUpdated({ dispatch }, scheduledMessage) {
    dispatch('scheduledMessages/upsertFromEvent', scheduledMessage);
  },

  handleScheduledMessageDeleted({ dispatch }, scheduledMessage) {
    dispatch('scheduledMessages/removeFromEvent', scheduledMessage);
  },

  handleRecurringScheduledMessageCreated(
    { dispatch },
    recurringScheduledMessage
  ) {
    dispatch(
      'recurringScheduledMessages/upsertFromEvent',
      recurringScheduledMessage
    );
  },

  handleRecurringScheduledMessageUpdated(
    { dispatch },
    recurringScheduledMessage
  ) {
    dispatch(
      'recurringScheduledMessages/upsertFromEvent',
      recurringScheduledMessage
    );
  },

  handleRecurringScheduledMessageDeleted(
    { dispatch },
    recurringScheduledMessage
  ) {
    dispatch(
      'recurringScheduledMessages/removeFromEvent',
      recurringScheduledMessage
    );
  },

  setActiveInbox({ commit }, inboxId) {
    commit(types.SET_ACTIVE_INBOX, inboxId);
  },

  muteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.mute(conversationId);
      commit(types.MUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },

  unmuteConversation: async ({ commit }, conversationId) => {
    try {
      await ConversationApi.unmute(conversationId);
      commit(types.UNMUTE_CONVERSATION);
    } catch (error) {
      //
    }
  },

  sendEmailTranscript: async (_, { conversationId, email }) => {
    await ConversationApi.sendEmailTranscript({ conversationId, email });
  },

  updateCustomAttributes: async (
    { commit },
    { conversationId, customAttributes }
  ) => {
    try {
      const response = await ConversationApi.updateCustomAttributes({
        conversationId,
        customAttributes,
      });
      const { custom_attributes } = response.data;
      commit(types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES, {
        conversationId,
        customAttributes: custom_attributes,
      });
    } catch (error) {
      rethrowWithResponse(error);
    }
  },

  setConversationFilters({ commit }, data) {
    commit(types.SET_CONVERSATION_FILTERS, data);
  },

  // Replaces the list with page 1 of the snake_case filters; sortBy overrides the activity order.
  applyConversationFilters: (
    { commit, dispatch },
    { filters, sortBy = null }
  ) => {
    const appliedFilters = filters.map(withTimestampTimezone);
    commit(types.SET_CONVERSATION_FILTERS, appliedFilters);
    commit(types.SET_CONVERSATION_FILTERS_SORT, sortBy);
    commit(types.EMPTY_ALL_CONVERSATION);
    dispatch('conversationPage/reset', {}, { root: true });

    return dispatch('fetchFilteredConversations', {
      queryData: filterQueryGenerator(appliedFilters),
      page: 1,
    });
  },

  clearConversationFilters({ commit }) {
    commit(types.CLEAR_CONVERSATION_FILTERS);
  },

  setChatListFilters({ commit }, data) {
    commit(types.SET_CHAT_LIST_FILTERS, data);
  },

  updateChatListFilters({ commit }, data) {
    commit(types.UPDATE_CHAT_LIST_FILTERS, data);
  },

  invalidateConversationListRequests({ commit }) {
    conversationListRequest.abort();
    commit(types.CLEAR_LIST_LOADING_STATUS);
  },

  assignPriority: async ({ dispatch }, { conversationId, priority }) => {
    try {
      await ConversationApi.togglePriority({
        conversationId,
        priority,
      });

      dispatch('setCurrentChatPriority', {
        priority,
        conversationId,
      });
    } catch (error) {
      // Handle error
    }
  },

  setCurrentChatPriority({ commit }, { priority, conversationId }) {
    commit(types.ASSIGN_PRIORITY, { priority, conversationId });
  },

  setContextMenuChatId({ commit }, chatId) {
    commit(types.SET_CONTEXT_MENU_CHAT_ID, chatId);
  },

  getInboxCaptainAssistantById: async ({ commit }, conversationId) => {
    try {
      const response = await ConversationApi.getInboxAssistant(conversationId);
      commit(types.SET_INBOX_CAPTAIN_ASSISTANT, response.data);
    } catch (error) {
      // Handle error
    }
  },

  ...messageReadActions,
  ...messageTranslateActions,
};

export default actions;
