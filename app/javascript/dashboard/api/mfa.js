/* global axios */
import ApiClient from './ApiClient';

class MfaAPI extends ApiClient {
  constructor() {
    super('profile/mfa', { accountScoped: false });
  }

  enable() {
    return axios.post(`${this.url}`);
  }

  verify(otpCode) {
    return axios.post(`${this.url}/verify`, { otp_code: otpCode });
  }

  disable(password, otpCode) {
    return axios.delete(this.url, {
      data: { password, otp_code: otpCode },
    });
  }

  regenerateBackupCodes(otpCode) {
    return axios.post(`${this.url}/backup_codes`, { otp_code: otpCode });
  }
}

export default new MfaAPI();
