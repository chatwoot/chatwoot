/* global axios */
import ApiClient from './ApiClient';

class FacebookTokenService extends ApiClient {
  constructor() {
    super('callbacks', { accountScoped: true });
  }

  // Kiểm tra trạng thái token Facebook
  checkTokenStatus(inboxId) {
    return axios.get(
      `${this.url}/facebook_token_status/${inboxId}`
    );
  }

  // Refresh token Facebook
  refreshToken(inboxId) {
    return axios.post(
      `${this.url}/refresh_facebook_token/${inboxId}`
    );
  }

  // Kiểm tra và refresh token nếu cần
  async ensureValidToken(inboxId) {
    try {
      // Kiểm tra trạng thái hiện tại
      const statusResponse = await this.checkTokenStatus(inboxId);
      const { token_valid, reauthorization_required } = statusResponse.data;

      if (!token_valid || reauthorization_required) {
        // Thử refresh token
        const refreshResponse = await this.refreshToken(inboxId);
        return {
          success: refreshResponse.data.success,
          message: refreshResponse.data.message,
          needsReauthorization: !refreshResponse.data.success
        };
      }

      return {
        success: true,
        message: 'Token is valid',
        needsReauthorization: false
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.error || error.message,
        needsReauthorization: true
      };
    }
  }

  // Kiểm tra trạng thái token cho nhiều inbox cùng lúc
  async checkMultipleTokens(inboxIds) {
    const results = await Promise.allSettled(
      inboxIds.map(inboxId => this.checkTokenStatus(inboxId))
    );

    return results.map((result, index) => {
      const inboxId = inboxIds[index];
      
      if (result.status === 'fulfilled') {
        return {
          inboxId,
          ...result.value.data
        };
      } else {
        return {
          inboxId,
          error: result.reason.response?.data?.error || result.reason.message,
          token_valid: false,
          reauthorization_required: true
        };
      }
    });
  }

  // Refresh token cho nhiều inbox cùng lúc
  async refreshMultipleTokens(inboxIds) {
    const results = await Promise.allSettled(
      inboxIds.map(inboxId => this.refreshToken(inboxId))
    );

    return results.map((result, index) => {
      const inboxId = inboxIds[index];
      
      if (result.status === 'fulfilled') {
        return {
          inboxId,
          ...result.value.data
        };
      } else {
        return {
          inboxId,
          success: false,
          error: result.reason.response?.data?.error || result.reason.message
        };
      }
    });
  }
}

export default new FacebookTokenService();
