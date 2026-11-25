require 'rails_helper'

# The default Rails direct-upload route has no authenticated caller: the dashboard
# and widget both upload through the scoped /api/v1/... endpoints. It is blocked so
# it cannot be used to create blobs anonymously.
RSpec.describe '/rails/active_storage/direct_uploads', type: :request do
  let(:params) do
    {
      blob: {
        filename: 'avatar.png',
        byte_size: '1234',
        checksum: 'dsjbsdhbfif3874823mnsdbf',
        content_type: 'image/png'
      }
    }
  end

  describe 'POST /rails/active_storage/direct_uploads' do
    it 'is blocked and creates no blob' do
      expect do
        post rails_direct_uploads_url, params: params
      end.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
