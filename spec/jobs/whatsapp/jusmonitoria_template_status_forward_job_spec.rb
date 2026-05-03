require 'rails_helper'

RSpec.describe Whatsapp::JusmonitoriaTemplateStatusForwardJob do
  describe '#perform' do
    it 'posts the template status update to JusMonitorIA with the internal API key' do
      payload = {
        provider: 'meta_whatsapp',
        wabaId: '294585820394901',
        event: 'APPROVED',
        status: 'approved',
        messageTemplateId: '987654321',
        messageTemplateName: 'alerta_movimentacao_processual_v2',
        messageTemplateLanguage: 'pt_BR',
        reason: nil,
        raw: { source: 'meta' }
      }
      allow(GlobalConfigService).to receive(:load)
        .with('JUSMONITORIA_INTERNAL_WEBHOOK_URL', '')
        .and_return('https://jusmonitoria.example.com/api/v1/jusmonitoria/internal/meta/template-status-update')
      allow(GlobalConfigService).to receive(:load)
        .with('JUSMONITORIA_INTERNAL_WEBHOOK_TOKEN', '')
        .and_return('jm-secret')
      stub = stub_request(
        :post,
        'https://jusmonitoria.example.com/api/v1/jusmonitoria/internal/meta/template-status-update'
      ).with(
        headers: {
          'Content-Type' => 'application/json',
          'X-Internal-API-Key' => 'jm-secret'
        },
        body: payload.to_json
      ).to_return(status: 200, body: { ok: true }.to_json)

      described_class.perform_now(payload)

      expect(stub).to have_been_requested
    end
  end
end
