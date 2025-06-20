/* global axios */
import ApiClient from './ApiClient';

class ApplicationsAPI extends ApiClient {
  constructor() {
    super('applications', { accountScoped: true });
  }

  // Simplificar os métodos para usar a funcionalidade padrão do ApiClient
  updateLastUsed(id) {
    // Corrigir a rota conforme mostrado no rails routes
    return axios.patch(`${this.url}/${id}/update_last_used`);
  }

  launch(id) {
    return axios.get(`${this.url}/${id}/launch`);
  }
}

export default new ApplicationsAPI();
