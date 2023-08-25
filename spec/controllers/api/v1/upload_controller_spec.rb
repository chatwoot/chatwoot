require 'rails_helper'

RSpec.describe 'Api::V1::UploadController', type: :request do
  describe 'POST /api/v1/upload/' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }

    it 'uploads the image' do
      file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')

      post '/api/v1/upload/',
           headers: user.create_new_auth_token,
           params: { attachment: file }

      expect(response).to have_http_status(:success)
      blob = response.parsed_body

      expect(blob['file_url']).to be_present
    end
  end
end
