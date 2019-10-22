/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from '../endPoints';

export default {
  fetchAllConversations(params, callback) {
    const urlData = endPoints('getInbox');

    if (params.inbox !== 0) {
      urlData.params.inbox_id = params.inbox;
    } else {
      urlData.params.inbox_id = null;
    }
    urlData.params = {
      ...urlData.params,
      conversation_status_id: params.convStatus,
      assignee_type_id: params.assigneeStatus,
    };
    axios
      .get(urlData.url, {
        params: urlData.params,
      })
      .then(response => {
        callback(response);
      })
      .catch(error => {
        console.log(error);
      });
  },
};
