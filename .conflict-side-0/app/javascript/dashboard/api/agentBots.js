/* global axios */
import ApiClient from './ApiClient';

class AgentBotsAPI extends ApiClient {
  constructor() {
    super('agent_bots', { accountScoped: true });
  }

  create(data) {
    return axios.post(this.url, data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  deleteAgentBotAvatar(botId) {
    return axios.delete(`${this.url}/${botId}/avatar`);
  }

  resetAccessToken(botId) {
    return axios.post(`${this.url}/${botId}/reset_access_token`);
  }
}

export default new AgentBotsAPI();
