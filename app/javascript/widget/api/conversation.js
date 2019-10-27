import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const sendMessageAPI = async content => {
  const urlData = endPoints.sendMessage(content);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

const getConversationAPI = async conversationId => {
  const urlData = endPoints.getConversation(conversationId);
  const result = await API.get(urlData.url);
  return result;
};

export { sendMessageAPI, getConversationAPI };
