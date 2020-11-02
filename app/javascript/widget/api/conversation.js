import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const sendMessageAPI = async ({ content, conversationId }) => {
  const urlData = endPoints.sendMessage({ content, conversationId });
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const sendAttachmentAPI = async ({ attachment, conversationId }) => {
  const urlData = endPoints.sendAttachment({ attachment, conversationId });
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const getMessagesAPI = async ({ before, conversationId }) => {
  const urlData = endPoints.getMessages({ before, conversationId });
  const result = await API.get(urlData.url, { params: urlData.params });
  return result;
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${window.location.search}`);
};

const toggleTyping = async ({ typingStatus, conversationId }) => {
  return API.post(
    `/api/v1/widget/conversations/${conversationId}/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

const setUserLastSeenAt = async ({ lastSeen, conversationId }) => {
  return API.post(
    `/api/v1/widget/conversations/${conversationId}/update_last_seen${window.location.search}`,
    { contact_last_seen_at: lastSeen }
  );
};

export {
  sendMessageAPI,
  getConversationAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
};
