import ApiClient from './ApiClient';

class LibraryResourcesAPI extends ApiClient {
  constructor() {
    super('library_resources', { accountScoped: true });
  }
}

export default new LibraryResourcesAPI();
