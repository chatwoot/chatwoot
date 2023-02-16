import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  return API.post(urlData.url, urlData.params);
};

const sendMessageAPI = async content => {
  const urlData = endPoints.sendMessage(content);
  return API.post(urlData.url, urlData.params);
};

const sendAttachmentAPI = async attachment => {
  const urlData = endPoints.sendAttachment(attachment);
  return API.post(urlData.url, urlData.params);
};

const getMessagesAPI = async ({ before }) => {
  const urlData = endPoints.getConversation({ before });
  return API.get(urlData.url, { params: urlData.params });
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${window.location.search}`);
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async ({ email }) => {
  return API.post(
    `/api/v1/widget/conversations/transcript${window.location.search}`,
    { email }
  );
};
const toggleStatus = async () => {
  return API.get(
    `/api/v1/widget/conversations/toggle_status${window.location.search}`
  );
};

export {
  createConversationAPI,
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  sendEmailTranscript,
  toggleStatus,
};
