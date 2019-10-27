/* eslint-disable no-param-reassign */
import Vue from 'vue';
// import authAPI from 'widget/api/auth';

// initial state
const state = {
  accountId: null,
  inboxId: null,
  contact: {},
  lastConversation: null,
};

// getters
const getters = {
  contactId($state) {
    return $state.contact.id;
  },
};

// actions
const actions = {
  initContact({ commit }, data) {
    commit('setContactData', data);
  },

  initWidget({ commit }, data) {
    commit('setWidgetData', data);
  },

  fetchContact() {
    // const { inboxId, accountId } = params;
    // authAPI
    //   .createContact(inboxId, accountId)
    //   .then(contact => {
    //     const { data } = contact;
    //     commit('setContactData', data);
    //     const message = {
    //       event: 'setContact',
    //       data,
    //     };
    //     window.parent.postMessage(JSON.stringify(message), '*');
    //     // const { chat_channel: chatChannel } = data;
    //     console.log(data);
    //   })
    //   .catch(error => console.log(error));
  },
};

// mutations
const mutations = {
  setContactData($state, data) {
    Vue.set($state, 'contact', data);
  },

  setLastConversation($state, conversationId) {
    $state.lastConversation = conversationId;
  },

  setWidgetData($state, data) {
    const { inboxId, accountId } = data;
    $state.inboxId = inboxId;
    $state.accountId = accountId;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
