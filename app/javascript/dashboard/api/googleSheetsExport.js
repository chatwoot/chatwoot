/* global axios */

import ApiClient from "./ApiClient"

class GoogleSheetsExportAPI extends ApiClient {
  constructor() {
    super("google_sheets_export", { accountScoped: true, apiVersion: "v2" })
  }

  getStatus() {
    console.log("Calling getStatus API...");
    return this.get("status")
  }

  getAuthorizationUrl() {
    return this.get("authorize")
  }

  disconnectAccount() {
    return this.delete('disconnect');
  }

  createSpreadsheet(payload) {
    return axios.post(`${this.url}/generate`, payload);
  }

  getSpreadsheetUrl(payload) {
    return axios.post(`${this.url}/spreadsheet_url`, payload);
  }

  syncSpreadsheet(payload) {
    return axios.post(`${this.url}/sync`, payload);
  }
}

export default new GoogleSheetsExportAPI()