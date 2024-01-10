require 'rails_helper'

RSpec.describe SlackUploadsController do
  describe 'GET #show' do
    context 'when a valid blob key is provided' do
      file = Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png')
      blob = ActiveStorage::Blob.create_and_upload! io: file, filename: 'avatar.png'

      it 'redirects to the blob service URL' do
        get :show, params: { blob_key: blob.key }
        redirect_path = response.location
        expect(redirect_path).to match(%r{rails/active_storage/representations/redirect/.*/avatar.png})
      end
    end

    context 'when an invalid blob key is provided' do
      it 'returns contact default avatar url if the user is contact' do
        get :show, params: { key: 'invalid_key', sender_type: 'contact' }
        redirect_path = response.location
        expect(redirect_path).to match(%r{integrations/slack/contact.png})
      end

      it 'returns agent default avatar url if the user is agent' do
        get :show, params: { key: 'invalid_key', sender_type: 'user' }
        redirect_path = response.location
        expect(redirect_path).to match(%r{integrations/slack/user.png})
      end
    end

    context 'when no blob key is provided' do
      it 'returns contact default avatar url if the user is contact' do
        get :show, params: { sender_type: 'contact' }
        redirect_path = response.location
        expect(redirect_path).to match(%r{integrations/slack/contact.png})
      end

      it 'returns agent default avatar url if the user is agent' do
        get :show, params: { sender_type: 'user' }
        redirect_path = response.location
        expect(redirect_path).to match(%r{integrations/slack/user.png})
      end
    end
  end
end
