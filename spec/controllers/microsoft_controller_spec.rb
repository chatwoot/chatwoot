require 'rails_helper'

describe '/.well-known/microsoft-identity-association.json', type: :request do
  describe 'GET /.well-known/microsoft-identity-association.json' do
    it 'successfully retrieves assetlinks.json file' do
      with_modified_env AZURE_APP_ID: 'azure-application-client-id' do
        get '/.well-known/microsoft-identity-association.json'
        expect(response).to have_http_status(:success)
        expect(response.body).to include '"applicationId":  "azure-application-client-id"'
      end
    end
  end
end
