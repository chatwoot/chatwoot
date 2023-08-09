/* eslint-disable class-methods-use-this */
import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export class ConversationsV3API {
  async create(content) {
    const urlData = endPoints.createConversation(content);
    return API.post(urlData.url, urlData.params);
  }

  async get() {
    return API.get(`/api/v1/widget/conversations${window.location.search}`);
  }

  async getMessages({ before, after }) {
    const urlData = endPoints.getConversation({ before, after });
    return API.get(urlData.url, { params: urlData.params });
  }

  async toggleTyping({ typingStatus }) {
    return API.post(
      `/api/v1/widget/conversations/toggle_typing${window.location.search}`,
      { typing_status: typingStatus }
    );
  }

  async setUserLastSeen({ lastSeen }) {
    return API.post(
      `/api/v1/widget/conversations/update_last_seen${window.location.search}`,
      { contact_last_seen_at: lastSeen }
    );
  }

  async emailTranscript({ email }) {
    return API.post(
      `/api/v1/widget/conversations/transcript${window.location.search}`,
      { email }
    );
  }

  async toggleStatus() {
    return API.get(
      `/api/v1/widget/conversations/toggle_status${window.location.search}`
    );
  }

  async setCustomAttributes(customAttributes) {
    return API.post(
      `/api/v1/widget/conversations/set_custom_attributes${window.location.search}`,
      {
        custom_attributes: customAttributes,
      }
    );
  }

  async deleteCustomAttribute(customAttribute) {
    return API.post(
      `/api/v1/widget/conversations/destroy_custom_attributes${window.location.search}`,
      {
        custom_attribute: [customAttribute],
      }
    );
  }
}

export default new ConversationsV3API();

export const sendMessageAPI = async content => {
  const urlData = endPoints.sendMessage(content);
  return API.post(urlData.url, urlData.params);
};

export const sendAttachmentAPI = async attachment => {
  const urlData = endPoints.sendAttachment({ attachment });
  return API.post(urlData.url, urlData.params);
};
