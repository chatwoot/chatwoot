/* global axios */
import ApiClient from './ApiClient';

class ProductCatalogAPI extends ApiClient {
  constructor() {
    super('product_catalogs', { accountScoped: true });
  }

  get({ page = 1, per_page = 50 } = {}) {
    return axios.get(this.url, {
      params: { page, per_page }
    });
  }

  bulkUpload(file) {
    const formData = new FormData();
    formData.append('file', file);

    return axios.post(
      `${this.url}/bulk_upload`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );
  }

  bulkDelete(ids) {
    return axios.post(`${this.url}/bulk_delete`, { ids });
  }

  export(ids) {
    return axios.post(
      `${this.url}/export`,
      { ids },
      {
        responseType: 'blob',
      }
    );
  }

  downloadTemplate() {
    return axios.get(
      `${this.url}/download_template`,
      {
        responseType: 'blob',
      }
    );
  }

  toggleVisibility(id) {
    return axios.post(`${this.url}/${id}/toggle_visibility`);
  }
}

export default new ProductCatalogAPI();
