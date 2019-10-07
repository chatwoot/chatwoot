/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  /**
   * handleGet
   * @param dataType {string} [dataType='agent', 'label', 'inbox'] type of data requested
   * @returns {promise}
   */
  handleGet(dataType) {
    let urlData;
    switch (dataType.toLowerCase()) {
      case 'agent':
        urlData = endPoints('fetchAgents');
      case 'label':
        urlData = endPoints('fetchLabels');
      case 'inbox':
        urlData = endPoints('fetchInboxes');
      default:
        reject('Incorrect query');
        return;
    }

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

  /**
   * handleDelete
   * @param dataType {string} [dataType='agent', 'label', 'inbox'] type of data requested
   * @param id {number} id of target data
   * @returns {promise}
   */
  handleDelete(dataType, id = 0) {
    if (!id) {
      reject('Incorrect query');
      return;
    }

    let urlData
    switch (dataType.toLowerCase()) {
      case 'agent':
        urlData = endPoints('deleteAgent')(id);
      case 'inbox':
        urlData = endPoints('deleteAgent').delete(id);
      default:
        reject('Incorrect query');
        return;
    }

    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .delete(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  addAgent(agentInfo) {
    const urlData = endPoints('addAgent');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, agentInfo)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
  editAgent(agentInfo) {
    const urlData = endPoints('editAgent')(agentInfo.id);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .put(urlData.url, agentInfo)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  listInboxAgents(id) {
    const urlData = endPoints('inbox').agents.get(id);
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

  updateInboxAgents(inboxId, agentList) {
    const urlData = endPoints('inbox').agents.post();
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, {
          user_ids: agentList,
          inbox_id: inboxId,
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
};
