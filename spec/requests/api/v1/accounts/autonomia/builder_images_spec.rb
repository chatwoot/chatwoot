require 'rails_helper'

# D3 (lado do upload) — o blob do builder nasce carimbado com a conta dona no
# metadata; é isso que o Builder valida ao resolver o signed_id.
RSpec.describe 'Autonomia builder images upload', type: :request do
  let(:account) { create(:account, internal_attributes: { 'autonomia_agents_enabled' => true }) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  around do |example|
    with_modified_env AUTONOMIA_AGENTS_ENABLED: 'true' do
      example.run
    end
  end

  describe 'POST /api/v1/accounts/:account_id/autonomia/builder_images' do
    it 'stamps the owning account on the blob metadata' do
      # Arrange
      tempfile = Tempfile.new(['pixel', '.png'], binmode: true)
      tempfile.write("\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR".b)
      tempfile.rewind
      file = Rack::Test::UploadedFile.new(tempfile.path, 'image/png')

      # Act
      post "/api/v1/accounts/#{account.id}/autonomia/builder_images",
           params: { file: file },
           headers: administrator.create_new_auth_token

      # Assert
      expect(response).to have_http_status(:success)
      signed_id = response.parsed_body['signed_id']
      blob = ActiveStorage::Blob.find_signed(signed_id, purpose: :autonomia_builder_image)
      expect(blob.metadata['autonomia_account_id']).to eq(account.id)
    end
  end
end
