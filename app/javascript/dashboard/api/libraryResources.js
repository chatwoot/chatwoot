/* global axios */

import ApiClient from './ApiClient';

class LibraryResourcesAPI extends ApiClient {
  constructor() {
    super('library_resources', { accountScoped: true });
  }

  upload(file) {
    const formData = new FormData();
    formData.append('attachment', file);

    return axios.post(`${this.url}/upload`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new LibraryResourcesAPI();
