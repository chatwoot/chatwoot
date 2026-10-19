/* global axios */
import ApiClient from '../ApiClient';

class CaptainToolsManifest extends ApiClient {
  constructor() {
    super('captain/tools_manifest', { accountScoped: true });
  }

  installed({ assistantId }, { signal } = {}) {
    return axios.get(`${this.url}/installed`, {
      params: { assistant_id: assistantId },
      signal,
    });
  }

  preview({ assistantId, source }, { signal } = {}) {
    return axios.post(
      `${this.url}/preview`,
      { assistant_id: assistantId, source },
      { signal }
    );
  }

  install({ assistantId, source, revision, configuration }) {
    return axios.post(`${this.url}/install`, {
      assistant_id: assistantId,
      source,
      revision,
      configuration,
    });
  }
}

export default new CaptainToolsManifest();
