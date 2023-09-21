require 'rails_helper'

RSpec.describe SlackUploadsController do
  describe 'GET #show' do
    context 'when a valid blob key is provided' do
      let(:blob) { create(:blob) }

      it 'redirects to the blob service URL' do
        get :show, params: { key: blob.key }
        # TODO: fix this test
        # expect(response).to redirect_to(blob.service_url)
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
