/* global axios */

import ApiClient from "./ApiClient"

class GoogleSheetsExportAPI extends ApiClient {
  constructor() {
    super("google_sheets_export", { accountScoped: true, apiVersion: "v2" })
  }

  getStatus() {
    return this.get("status")
  }

  getAuthorizationUrl() {
    return this.get("authorize")
  }

  createSpreadsheet(payload) {
    return axios.post(`${this.url}/generate`, payload);
  }

  getSpreadsheetUrl(payload) {
    return axios.post(`${this.url}/spreadsheet_url`, payload);
  }
}

export default new GoogleSheetsExportAPI()
