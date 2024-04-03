/* global axios */
// import axios from 'axios';
import ApiClient from './ApiClient';

class ChatbotAPI extends ApiClient {
  constructor() {
    super('chatbot', { accountScoped: true });
    this.baseUrl = window.chatwootConfig.hostURL;
    this.microserviceUrl = process.env.MICROSERVICE_URL;
  }

  // api call to microservice
  async createChatbot(data) {
    return axios.post(`${this.microserviceUrl}/chatbot`, data, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  // api call to ruby backend to store bot info in db
  async storeToDb(payload) {
    try {
      const response = await axios.post(
        `${this.baseUrl}/api/v1/widget/store-to-db`,
        payload,
        {
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );
      return response.data;
    } catch (error) {
      throw error.response.data.error || 'Failed to create chatbot';
    }
  }

  async fetchChatbotsWithAccountId(accountId) {
    return axios.get(
      `${this.baseUrl}/api/v1/widget/chatbot-with-account-id?account_id=${accountId}`
    );
  }

  async deleteChatbotWithChatbotId(chatbotId) {
    return axios.delete(
      `${this.baseUrl}/api/v1/widget/chatbot-with-chatbot-id?chatbot_id=${chatbotId}`
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
}

export default new ChatbotAPI();