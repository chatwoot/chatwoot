import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';
import { stripConversationToken } from 'widget/helpers/urlParamsHelper';

const widgetQuery = () => stripConversationToken(window.location.search);

const createConversationAPI = async content => {
  const urlData = endPoints.createConversation(content);
  return API.post(urlData.url, urlData.params);
};

const sendMessageAPI = async (
  content,
  replyTo = null,
  { customAttributes, labels } = {}
) => {
  const urlData = endPoints.sendMessage(content, replyTo, {
    customAttributes,
    labels,
  });
  return API.post(urlData.url, urlData.params);
};

const sendAttachmentAPI = async (
  attachment,
  { customAttributes, labels } = {}
) => {
  const urlData = endPoints.sendAttachment(attachment, {
    customAttributes,
    labels,
  });
  return API.post(urlData.url, urlData.params);
};

const getMessagesAPI = async ({ before, after }) => {
  const urlData = endPoints.getConversation({ before, after });
  return API.get(urlData.url, { params: urlData.params });
};

const getConversationAPI = async () => {
  return API.get(`/api/v1/widget/conversations${widgetQuery()}`);
};

const toggleTyping = async ({ typingStatus }) => {
  return API.post(
    `/api/v1/widget/conversations/toggle_typing${widgetQuery()}`,
    {
      typing_status: typingStatus,
    }
  );
};

const setUserLastSeenAt = async ({ lastSeen }) => {
  return API.post(
    `/api/v1/widget/conversations/update_last_seen${widgetQuery()}`,
    { contact_last_seen_at: lastSeen }
  );
};
const sendEmailTranscript = async () => {
  return API.post(`/api/v1/widget/conversations/transcript${widgetQuery()}`);
};
const toggleStatus = async () => {
  return API.get(`/api/v1/widget/conversations/toggle_status${widgetQuery()}`);
};

const setCustomAttributes = async customAttributes => {
  return API.post(
    `/api/v1/widget/conversations/set_custom_attributes${widgetQuery()}`,
    {
      custom_attributes: customAttributes,
    }
  );
};

const deleteCustomAttribute = async customAttribute => {
  return API.post(
    `/api/v1/widget/conversations/destroy_custom_attributes${widgetQuery()}`,
    {
      custom_attribute: [customAttribute],
    }
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
  setCustomAttributes,
  deleteCustomAttribute,
};
