/* global axios */
// import axios from 'axios';
import ApiClient from './ApiClient';

class ChatbotAPI extends ApiClient {
  constructor() {
    super('chatbot', { accountScoped: true });
    this.baseUrl = window.chatwootConfig.hostURL;
    this.microserviceUrl = process.env.MICROSERVICE_URL;
  }

  // api call to backend to microservice
  async createChatbot(data) {
    const formData = new FormData();
    formData.append('accountId', data.accountId);
    formData.append('website_token', data.website_token);
    formData.append('inbox_id', data.inbox_id);
    formData.append('inbox_name', data.inbox_name);
    formData.append('bot_files', data.bot_files);
    formData.append('bot_text', data.bot_text);
    formData.append('bot_urls', data.bot_urls);
    return axios.post(
      `${this.baseUrl}/api/v1/widget/create_chatbot`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );
  }

  async getChatbots(accountId) {
    return axios.get(
      `${this.baseUrl}/api/v1/widget/get_chatbots?account_id=${accountId}`
    );
  }

  async deleteChatbot(id) {
    return axios.delete(
      `${this.baseUrl}/api/v1/widget/delete_chatbot?id=${id}`
    );
  }

  async editBotInfo(payload) {
    return axios.put(`${this.baseUrl}/api/v1/widget/update-bot-info`, payload);
  }

  async toggleChatbotStatus(payload) {
    return axios.post(
      `${this.baseUrl}/api/v1/widget/toggle-chatbot-status`,
      payload
    );
  }

  async fetchChatbotStatus(conversation_id) {
    return axios.get(
      `${this.baseUrl}/api/v1/widget/chatbot-status?conversation_id=${conversation_id}`
    );
  }

  async ChatbotIdToChatbotName(chatbot_id) {
    return axios.get(
      `${this.baseUrl}/api/v1/widget/chatbot-id-to-name?chatbot_id=${chatbot_id}`
    );
  }

  async disconnectChatbot(chatbot_id) {
    return axios.delete(
      `${this.baseUrl}/api/v1/widget/disconnect-chatbot?chatbot_id=${chatbot_id}`
    );
  }
}

export default new ChatbotAPI();
