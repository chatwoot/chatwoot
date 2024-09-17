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

  async checkCrawlingStatus() {
    return axios.get(`${this.baseUrl()}/chatbots/check_crawling_status`);
  }

  async createChatbot(data) {
    const formData = new FormData();
    formData.append('accountId', data.accountId);
    formData.append('website_token', data.website_token);
    formData.append('inbox_id', data.inbox_id);
    formData.append('inbox_name', data.inbox_name);
    formData.append('text', data.text);
    formData.append('urls', JSON.stringify(data.urls));
    data.files.forEach((fileData, index) => {
      formData.append(`files[${index}][file]`, fileData.file);
      formData.append(`files[${index}][char_count]`, fileData.char_count);
    });
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
    formData.append('text', data.text);
    formData.append('urls', JSON.stringify(data.urls));
    data.files.forEach((fileData, index) => {
      formData.append(`files[${index}][file]`, fileData.file);
      formData.append(`files[${index}][char_count]`, fileData.char_count);
    });
    return axios.post(`${this.baseUrl()}/chatbots/retrain_chatbot`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  async getSavedData(id) {
    return axios.get(`${this.baseUrl()}/chatbots/saved_data?id=${id}`);
  }

  async processPdfFile(file) {
    const formData = new FormData();
    formData.append('file', file);
    return axios.post(`${this.baseUrl()}/chatbots/process_pdf`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  async destroyAttachment(data) {
    return axios.delete(`${this.baseUrl()}/chatbots/destroy_attachment`, {
      params: {
        chatbot_id: data.chatbot_id,
        attachment_id: data.id,
        filename: data.filename,
      },
    });
  }
}

export default new ChatbotAPI();
