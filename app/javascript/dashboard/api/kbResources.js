/* global axios */
import ApiClient from './ApiClient';

class KbResourcesAPI extends ApiClient {
  constructor() {
    super('kb_resources', { accountScoped: true });
  }

  get({
    page = 1,
    per_page = 50,
    q = undefined,
    product_catalog_id = undefined,
    folder_path = '/',
  } = {}) {
    const params = { page, per_page, folder_path };
    if (q) params.q = q;
    if (product_catalog_id) params.product_catalog_id = product_catalog_id;
    return axios.get(this.url, { params });
  }

  create(formData) {
    return axios.post(this.url, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { kb_resource: data });
  }

  toggleVisibility(id) {
    return axios.post(`${this.url}/${id}/toggle_visibility`);
  }

  getStorageInfo() {
    return axios.get(`${this.url}/storage_info`);
  }

  move(id, folderPath) {
    return axios.post(`${this.url}/${id}/move`, { folder_path: folderPath });
  }

  bulkMove(resourceIds, folderPath) {
    return axios.post(`${this.url}/bulk_move`, {
      resource_ids: resourceIds,
      folder_path: folderPath,
    });
  }

  createFolder(name, parentPath) {
    return axios.post(`${this.url}/create_folder`, {
      name,
      parent_path: parentPath,
    });
  }

  deleteFolder(folderPath, force = false) {
    return axios.delete(`${this.url}/delete_folder`, {
      params: { folder_path: folderPath, force },
    });
  }

  getTree() {
    return axios.get(`${this.url}/tree`);
  }
}

export default new KbResourcesAPI();
