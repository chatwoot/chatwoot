/* global axios */

const CHATWOOT_EXTRA_API_URL = (
  window.chatwootConfig?.chatwootExtraApiUrl || 'http://localhost:3001'
).replace(/\/$/, ''); // Remove trailing slash if present
const CHATWOOT_EXTRA_API_KEY = window.chatwootConfig?.chatwootExtraApiKey || '';

class ChatwootExtraAPI {
  constructor() {
    this.baseURL = CHATWOOT_EXTRA_API_URL;
    this.headers = {
      'Content-Type': 'application/json',
      'X-API-Key': CHATWOOT_EXTRA_API_KEY,
    };
  }

  async createMacro({ chatwootUserId, chatwootMacrosId, sourceChannelIds }) {
    const response = await axios.post(
      `${this.baseURL}/api/macros`,
      {
        chatwootUserId,
        chatwootMacrosId,
        sourceChannelIds,
      },
      { headers: this.headers }
    );
    // Backend returns { success: true, data: {...} }
    return response.data;
  }

  async getMacro(id) {
    try {
      const response = await axios.get(`${this.baseURL}/api/macros/${id}`, {
        headers: this.headers,
      });
      return response.data;
    } catch (error) {
      return null;
    }
  }

  async getMacrosByUser(chatwootUserId) {
    try {
      const response = await axios.get(
        `${this.baseURL}/api/macros/user/${chatwootUserId}`,
        { headers: this.headers }
      );
      // Backend returns { success: true, data: [...] }
      return response.data?.data || [];
    } catch (error) {
      return [];
    }
  }

  async getAllMacros() {
    try {
      const response = await axios.get(`${this.baseURL}/api/macros`, {
        headers: this.headers,
      });
      // Backend returns { success: true, data: [...] }
      return response.data?.data || [];
    } catch (error) {
      return [];
    }
  }

  async getMacrosByUserAndChannel(chatwootUserId, chatwootChannelId) {
    try {
      const response = await axios.get(
        `${this.baseURL}/api/macros/user/${chatwootUserId}/channel/${chatwootChannelId}`,
        { headers: this.headers }
      );
      return response.data;
    } catch (error) {
      return null;
    }
  }

  async updateMacroSources({
    chatwootUserId,
    chatwootMacrosId,
    sourceChannelIds,
  }) {
    const response = await axios.patch(
      `${this.baseURL}/api/macros/sources`,
      {
        chatwootUserId,
        chatwootMacrosId,
        sourceChannelIds,
      },
      { headers: this.headers }
    );
    // Backend returns { success: true, data: {...} }
    return response.data;
  }

  async deleteMacro(id) {
    const response = await axios.delete(`${this.baseURL}/api/macros/${id}`, {
      headers: this.headers,
    });
    return response.data;
  }

  async getSourceChannel(chatwootChannelId) {
    const response = await axios.get(
      `${this.baseURL}/api/source-channels/${chatwootChannelId}`,
      { headers: this.headers }
    );
    return response.data;
  }

  async updateSourceChannel(chatwootChannelId, data) {
    const response = await axios.patch(
      `${this.baseURL}/api/source-channels/${chatwootChannelId}`,
      data,
      { headers: this.headers }
    );
    return response.data;
  }
}

export default new ChatwootExtraAPI();
