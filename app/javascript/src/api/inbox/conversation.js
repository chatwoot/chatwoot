/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from '../endPoints';

export default {
  fetchConversation(id) {
    const urlData = endPoints('conversations')(id);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  toggleStatus(id) {
    const urlData = endPoints('resolveConversation')(id);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  assignAgent([id, agentId]) {
    const urlData = endPoints('assignAgent')(id, agentId);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  markSeen({ inboxId, senderId }) {
    const urlData = endPoints('fbMarkSeen');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, {
          inbox_id: inboxId,
          sender_id: senderId,
        })
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  fbTyping({ flag, inboxId, senderId }) {
    const urlData = endPoints('fbTyping')(flag);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, {
          inbox_id: inboxId,
          sender_id: senderId,
        })
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  markMessageRead({ id, lastSeen }) {
    const urlData = endPoints('markMessageRead')(id);
    urlData.params.agent_last_seen_at = lastSeen;
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, urlData.params)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
};
