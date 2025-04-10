/* global axios */
import ApiClient from './ApiClient';

class AgentBotsAPI extends ApiClient {
  constructor() {
    super('agent_bots', { accountScoped: true });
  }

  create(data) {
    // If data is FormData, use it directly
    if (data instanceof FormData) {
      return axios.post(this.url, data, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
    }

    // Otherwise, use the default create method
    return super.create(data);
  }

  update(id, data) {
    // If data is FormData, use it directly
    if (data instanceof FormData) {
      return axios.patch(`${this.url}/${id}`, data, {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      });
    }

    // Otherwise, use the default update method
    return super.update(id, data);
  }

  deleteAgentBotAvatar(botId) {
    return axios.delete(`${this.url}/${botId}/avatar`);
  }
}

export default new AgentBotsAPI();
