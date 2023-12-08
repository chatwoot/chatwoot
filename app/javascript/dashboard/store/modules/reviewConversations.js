import Vue from 'vue';
import BootstrapAPI from '../../api/bootstrap';
import { getUnixTime, parseISO } from 'date-fns';
import db from '../../database';

const state = {
  conversations: {},
  labels: {},
};

const MUTATIONS = {
  SET_CONVERSATIONS: 'SET_CONVERSATIONS',
  SET_LABELS: 'SET_LABELS',
};

const statusMapping = { 0: 'open', 1: 'resolved', 2: 'pending', 3: 'snoozed' };
const priorityMapping = { 0: 'low', 1: 'medium', 2: 'high', 3: 'urgent' };
const getTimestamp = timestamp => {
  if (timestamp) {
    return getUnixTime(parseISO(timestamp));
  }
  return null;
};

export const getters = {
  getAll: $state =>
    Object.keys($state.conversations)
      .sort((c1, c2) => c2 - c1)
      .map(conversationId => ({
        ...$state.conversations[conversationId],
        labels: $state.labels[conversationId] || [],
      })),
  getOne: $state => id => $state.conversations[id],
  getLabels: $state => id => $state.labels[id] || [],
};

export const actions = {
  async bootstrap({ commit }) {
    const oldConversations = await db.conversations.toArray();
    console.log(oldConversations);
    commit(MUTATIONS.SET_CONVERSATIONS, oldConversations);
    // const { data } = await BootstrapAPI.conversations();

    // const conversations = data.map(conversation => {
    //   const {
    //     assignee_id: assigneeId,
    //     inbox_id: inboxId,
    //     account_id: accountId,
    //     created_at: createdAt,
    //     updated_at: updatedAt,
    //     contact_id: contactId,
    //     agent_last_seen_at: agentLastSeenAt,
    //     additional_attributes: additionalAttributes,
    //     last_activity_at: lastActivityAt,
    //     team_id: teamId,
    //     snoozed_until: snoozedUntil,
    //     custom_attributes: customAttributes,
    //     first_reply_created_at: firstReplyCreatedAt,
    //     waiting_since: waitingSince,
    //     priority,
    //     status,
    //     ...restOfTheAttributes
    //   } = conversation;

    //   return {
    //     assigneeId,
    //     inboxId,
    //     accountId,
    //     createdAt: getTimestamp(createdAt),
    //     updatedAt: getTimestamp(updatedAt),
    //     contactId,
    //     agentLastSeenAt: getTimestamp(agentLastSeenAt),
    //     additionalAttributes,
    //     lastActivityAt: getTimestamp(lastActivityAt),
    //     teamId,
    //     snoozedUntil,
    //     customAttributes,
    //     firstReplyCreatedAt: getTimestamp(firstReplyCreatedAt),
    //     waitingSince,
    //     priority: priorityMapping[priority],
    //     status: statusMapping[status],
    //     ...restOfTheAttributes,
    //   };
    // });
    // try {
    //   await db.conversations.bulkPut(conversations);
    //   commit(MUTATIONS.SET_CONVERSATIONS, conversations);
    // } catch (e) {
    //   alert(`Error: ${e}`);
    // }
  },
  async labelsBootstrap({ commit }) {
    const { data } = await BootstrapAPI.conversationLabels();
    commit(MUTATIONS.SET_LABELS, data, 1);
  },
};

export const mutations = {
  [MUTATIONS.SET_CONVERSATIONS]($state, conversations) {
    conversations.forEach(conversation => {
      Vue.set($state.conversations, conversation.id, conversation);
    });
  },
  [MUTATIONS.SET_LABELS]($state, labelList) {
    labelList.forEach(labelItem => {
      Vue.set($state.labels, labelItem.id, labelItem.labels);
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
