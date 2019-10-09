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
        break;
      case 'label':
        urlData = endPoints('fetchLabels');
        break;
      case 'inbox':
        urlData = endPoints('fetchInboxes');
        break;
      default:
        break;
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
//     if (!id) {
//       console.log('Incorrect query');
//       return;
//     }

    let urlData
    switch (dataType.toLowerCase()) {
      case 'agent':
        urlData = endPoints('deleteAgent')(id);
        break;
      case 'inbox':
        urlData = endPoints('inbox').delete(id);
        break;
      default:
        break;
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
  getAgents() {
    const urlData = endPoints('fetchAgents');
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
  deleteAgent(agentId) {
    const urlData = endPoints('deleteAgent')(agentId);
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
  getLabels() {
    const urlData = endPoints('fetchLabels');
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
  // Get Inbox related to the account
  getInboxes() {
    const urlData = endPoints('fetchInboxes');
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
  deleteInbox(id) {
    const urlData = endPoints('inbox').delete(id);
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
