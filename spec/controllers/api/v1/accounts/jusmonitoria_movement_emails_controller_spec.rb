require 'rails_helper'

RSpec.describe Api::V1::Accounts::JusmonitoriaMovementEmailsController, type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/{account.id}/jusmonitoria_movement_email' do
    it 'queues a JusMonitorIA movement notification email' do
      post "/api/v1/accounts/#{account.id}/jusmonitoria_movement_email",
           headers: admin.create_new_auth_token,
           params: {
             to: 'advogada@firm.test',
             subject: 'Novas movimentações no processo 0001',
             html_content: '<p>Movimentação nova</p>',
             text_content: 'Movimentação nova'
           },
           as: :json

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body).to include('queued' => true)
    end

    it 'rejects payload without recipient email' do
      post "/api/v1/accounts/#{account.id}/jusmonitoria_movement_email",
           headers: admin.create_new_auth_token,
           params: {
             subject: 'Novas movimentações no processo 0001',
             html_content: '<p>Movimentação nova</p>'
           },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
