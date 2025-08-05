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
}

export default new GoogleSheetsExportAPI()
