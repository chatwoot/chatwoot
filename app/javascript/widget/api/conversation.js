import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const sendMessageAPI = async content => {
  const urlData = endPoints.sendMessage(content);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const sendAttachmentAPI = async attachment => {
  const urlData = endPoints.sendAttachment(attachment);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const getConversationAPI = async ({ before }) => {
  const urlData = endPoints.getConversation({ before });
  const result = await API.get(urlData.url, { params: urlData.params });
  return result;
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
    { typing_status: typingStatus }
  );
};

export { sendMessageAPI, getConversationAPI, sendAttachmentAPI, toggleTyping };
