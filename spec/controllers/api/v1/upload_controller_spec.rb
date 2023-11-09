require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::UploadController', type: :request do
  describe 'POST /api/v1/account/1/upload/' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }

    it 'uploads the image when authorized' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

      post "/api/v1/accounts/#{account.id}/upload/",
           headers: user.create_new_auth_token,
           params: { attachment: file }

      expect(response).to have_http_status(:success)
      blob = response.parsed_body

      expect(blob['errors']).to be_nil

      expect(blob['file_url']).to be_present
      expect(blob['blob_key']).to be_present
      expect(blob['blob_id']).to be_present
    end

    it 'does not upload when un-authorized' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

      post "/api/v1/accounts/#{account.id}/upload/",
           headers: {},
           params: { attachment: file }

      expect(response).to have_http_status(:unauthorized)
      blob = response.parsed_body

      expect(blob['errors']).to be_present

      expect(blob['file_url']).to be_nil
      expect(blob['blob_key']).to be_nil
      expect(blob['blob_id']).to be_nil
    end
  end
end
