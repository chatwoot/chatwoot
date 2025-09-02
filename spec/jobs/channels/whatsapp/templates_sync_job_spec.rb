require 'rails_helper'

RSpec.describe Channels::Whatsapp::TemplatesSyncJob do
  # Add WebMock stubs for WhatsApp 360Dialog API calls to prevent external requests during tests
  before do
    # Stub 360Dialog webhook configuration API call
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '', headers: {})
    
    # Stub 360Dialog templates API call - this was missing and causing the test failures
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: '{"waba_templates": []}', headers: { 'Content-Type' => 'application/json' })
  end

  let(:channel_whatsapp) { create(:channel_whatsapp, sync_templates: false) }

  it 'enqueues the job' do
    expect { described_class.perform_later(channel_whatsapp) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'calls sync_templates' do
      whatsapp_channel = double
      allow(whatsapp_channel).to receive(:sync_templates).and_return(true)
      expect(whatsapp_channel).to receive(:sync_templates)
      described_class.perform_now(whatsapp_channel)
    end
  end
end
