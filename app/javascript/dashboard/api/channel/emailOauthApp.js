/* global axios */
import ApiClient from '../ApiClient';

// Credenciais POR CONTA do app OAuth de e-mail (Microsoft/Google).
class EmailOauthAppAPI extends ApiClient {
  constructor() {
    super('email_oauth_apps', { accountScoped: true });
  }

  get(provider) {
    return axios.get(`${this.url}/${provider}`);
  }

  update(provider, { clientId, clientSecret, redirectUri, tenantId }) {
    return axios.put(`${this.url}/${provider}`, {
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      tenant_id: tenantId,
    });
  }
}

export default new EmailOauthAppAPI();
