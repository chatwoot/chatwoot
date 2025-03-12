require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::UploadController', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:upload_url) { "/api/v1/accounts/#{account.id}/upload/" }

  describe 'POST /api/v1/accounts/:account_id/upload/' do
    context 'when uploading a file' do
      let(:file) { fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png') }

      it 'uploads the image when authorized' do
        post upload_url,
             headers: user.create_new_auth_token,
             params: { attachment: file }

        expect(response).to have_http_status(:success)
        blob = response.parsed_body
        expect(blob['errors']).to be_nil
        expect(blob['file_url']).to be_present
        expect(blob['blob_key']).to be_present
        expect(blob['blob_id']).to be_present
      end

      it 'does not upload when unauthorized' do
        post upload_url,
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

    context 'when uploading from a URL' do
      let(:valid_external_url) { 'http://example.com/image.jpg' }

      before do
        stub_request(:get, valid_external_url)
          .to_return(status: 200, body: File.new(Rails.root.join('spec/assets/avatar.png')), headers: { 'Content-Type' => 'image/png' })
      end

      it 'uploads the image from URL when authorized' do
        post upload_url,
             headers: user.create_new_auth_token,
             params: { external_url: valid_external_url }

        expect(response).to have_http_status(:success)
        blob = response.parsed_body
        expect(blob['error']).to be_nil
        expect(blob['file_url']).to be_present
        expect(blob['blob_key']).to be_present
        expect(blob['blob_id']).to be_present
      end

      it 'handles invalid URL format' do
        post upload_url,
             headers: user.create_new_auth_token,
             params: { external_url: 'not_a_url' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Invalid URL provided')
      end

      it 'handles URL with unsupported protocol' do
        post upload_url,
             headers: user.create_new_auth_token,
             params: { external_url: 'ftp://example.com/image.jpg' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Invalid URL provided')
      end

      it 'handles unreachable URLs' do
        stub_request(:get, 'http://nonexistent.example.com')
          .to_raise(SocketError.new('Failed to open TCP connection'))

        post upload_url,
             headers: user.create_new_auth_token,
             params: { external_url: 'http://nonexistent.example.com' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq('Invalid URL provided')
      end

      it 'handles HTTP errors' do
        stub_request(:get, 'http://error.example.com')
          .to_return(status: 404)

        post upload_url,
             headers: user.create_new_auth_token,
             params: { external_url: 'http://error.example.com' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to start_with('Failed to fetch file from URL')
      end
    end

    it 'returns an error when no file or URL is provided' do
      post upload_url,
           headers: user.create_new_auth_token,
           params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('No file or URL provided')
    end
  end
end
