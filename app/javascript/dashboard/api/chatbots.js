/* global axios */
// import axios from 'axios';
import ApiClient from './ApiClient';

class ChatbotAPI extends ApiClient {
  constructor() {
    super('chatbots', { accountScoped: true });
  }

  async fetchLinks(url) {
    return axios.post(`${this.baseUrl()}/chatbots/fetch_links?url=${url}`);
  }

  async createChatbot(data) {
    const formData = new FormData();
    formData.append('accountId', data.accountId);
    formData.append('website_token', data.website_token);
    formData.append('inbox_id', data.inbox_id);
    formData.append('inbox_name', data.inbox_name);
    formData.append('files', data.files);
    formData.append('text', data.text);
    formData.append('urls', JSON.stringify(data.urls));
    return axios.post(`${this.baseUrl()}/chatbots/create_chatbot`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  async deleteChatbot(id) {
    return axios.delete(`${this.baseUrl()}/chatbots/destroy_chatbot?id=${id}`);
  }

  async retrainChatbot(data) {
    const formData = new FormData();
    formData.append('accountId', data.accountId);
    formData.append('chatbotId', data.chatbotId);
    formData.append('files', data.files);
    formData.append('text', data.text);
    formData.append('urls', JSON.stringify(data.urls));
    return axios.post(`${this.baseUrl()}/chatbots/retrain_chatbot`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  async getSavedLinks(id) {
    return axios.get(`${this.baseUrl()}/chatbots/saved_links?id=${id}`);
  }
}

export default new ChatbotAPI();
