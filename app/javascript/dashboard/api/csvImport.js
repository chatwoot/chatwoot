/* global axios */
import ApiClient from './ApiClient';

// Kiraid: modular CSV contact/company importer endpoint. Remove this file
// together with CsvImportController and app/services/csv_import to drop the
// feature.
class CsvImportAPI extends ApiClient {
  constructor() {
    super('csv_import', { accountScoped: true });
  }

  import(file, inboxId = null) {
    const formData = new FormData();
    formData.append('import_file', file);
    if (inboxId) formData.append('inbox_id', inboxId);
    return axios.post(this.url, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }
}

export default new CsvImportAPI();
