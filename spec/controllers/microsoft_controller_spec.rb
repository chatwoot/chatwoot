require 'rails_helper'

describe '/.well-known/microsoft-identity-association.json', type: :request do
  describe 'GET /.well-known/microsoft-identity-association.json' do
    it 'successfully retrieves assetlinks.json file' do
      with_modified_env AZURE_APP_ID: 'azure-application-client-id' do
        get '/.well-known/microsoft-identity-association.json'
        expect(response).to have_http_status(:success)
        expect(response.body).to include '"applicationId":"azure-application-client-id"'

        content_length = { associatedApplications: [{ applicationId: 'azure-application-client-id' }] }.to_json.length

        expect(response.headers['Content-Length']).to eq(content_length.to_s)
      end
    end
  end
end
