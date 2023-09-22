require 'rails_helper'

RSpec.describe SlackUploadsController do
  describe 'GET #show' do
    context 'when a valid blob key is provided' do
      file = Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')
      blob = ActiveStorage::Blob.create_and_upload! io: file, filename: 'avatar.png'

      it 'redirects to the blob service URL' do
        get :show, params: { key: blob.key }
        redirect_path = response.location
        expect(redirect_path).to match(%r{rails/active_storage/representations/redirect/.*/avatar.png})
      end
    end

    context 'when an invalid blob key is provided' do
      it 'returns a 404 not found response' do
        get :show, params: { key: 'invalid_key' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
