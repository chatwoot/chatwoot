require 'rails_helper'

RSpec.describe Channels::Whatsapp::TemplatesSyncJob, type: :job do
  let(:channel_whatsapp) { create(:channel_whatsapp, sync_templates: false) }

  it 'enqueues the job' do
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
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
