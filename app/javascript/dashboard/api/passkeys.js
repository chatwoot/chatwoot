/* global axios */
import ApiClient from './ApiClient';

class PasskeysAPI extends ApiClient {
  constructor() {
    super('profile/passkeys', { accountScoped: false });
  }

  registrationOptions({ password, otpCode, backupCode }) {
    return axios.post(`${this.url}/registration_options`, {
      password,
      otp_code: otpCode,
      backup_code: backupCode,
    });
  }

  register(credential, name) {
    return axios.post(this.url, { credential, name });
  }
}

export default new PasskeysAPI();
