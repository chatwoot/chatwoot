/* global axios */
import ApiClient from '../ApiClient';

class CaptainCustomTools extends ApiClient {
  constructor() {
    super('captain/custom_tools', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: { page, searchKey },
    });
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(data = {}) {
    return axios.post(this.url, {
      custom_tool: data,
    });
  }

  update(id, data = {}) {
    return axios.put(`${this.url}/${id}`, {
      custom_tool: data,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  test(data = {}) {
    return axios.post(`${this.url}/test`, {
      custom_tool: data,
    });
  }

  previewImport({ file, source }, { signal } = {}) {
    const formData = new FormData();
    if (file) formData.append('file', file);
    if (source) formData.append('source', source);
    return axios.post(`${this.url}/preview_import`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      signal,
    });
  }

  importToolset({ file, source }, configuration) {
    const formData = new FormData();
    if (file) formData.append('file', file);
    if (source) formData.append('source', source);
    formData.append('configuration', JSON.stringify(configuration));
    return axios.post(`${this.url}/import`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  exportToolset(id) {
    return axios.get(`${this.url}/${id}/export`, { responseType: 'blob' });
  }
}

export default new CaptainCustomTools();
