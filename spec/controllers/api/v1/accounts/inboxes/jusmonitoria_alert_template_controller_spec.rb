require 'rails_helper'

RSpec.describe Api::V1::Accounts::Inboxes::JusmonitoriaAlertTemplateController, type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
  end
  let(:whatsapp_inbox) { whatsapp_channel.inbox }
  let(:service) { instance_double(Whatsapp::JusmonitoriaAlertTemplateService) }

  before do
    allow(Whatsapp::JusmonitoriaAlertTemplateService).to receive(:new).with(whatsapp_inbox).and_return(service)
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox.id}/jusmonitoria_alert_template' do
    it 'returns the fixed movement alert template status' do
      allow(service).to receive(:status).and_return(
        provider: 'whatsapp_cloud',
        template_required: true,
        template_name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        template_status: 'approved',
        delivery_locked: false
      )

      get "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/jusmonitoria_alert_template",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'provider' => 'whatsapp_cloud',
        'template_name' => 'alerta_movimentacao_processual_v1',
        'template_status' => 'approved',
        'delivery_locked' => false
      )
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inboxes/{inbox.id}/jusmonitoria_alert_template' do
    it 'creates the fixed movement alert template' do
      allow(service).to receive(:create).and_return(
        provider: 'whatsapp_cloud',
        template_required: true,
        template_name: 'alerta_movimentacao_processual_v1',
        language: 'pt_BR',
        template_status: 'pending',
        delivery_locked: true,
        created: true
      )

      post "/api/v1/accounts/#{account.id}/inboxes/#{whatsapp_inbox.id}/jusmonitoria_alert_template",
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include(
        'template_name' => 'alerta_movimentacao_processual_v1',
        'template_status' => 'pending',
        'created' => true
      )
    end
  end
end
