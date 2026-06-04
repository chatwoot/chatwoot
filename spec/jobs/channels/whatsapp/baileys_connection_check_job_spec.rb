require 'rails_helper'

RSpec.describe Channels::Whatsapp::BaileysConnectionCheckJob do
  let(:channel_whatsapp) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }

  it 'enqueues the job' do
    expect { described_class.perform_later(channel_whatsapp) }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'calls setup_channel_provider' do
      allow(channel_whatsapp).to receive(:setup_channel_provider).and_return(true)

      described_class.perform_now(channel_whatsapp)

      expect(channel_whatsapp).to have_received(:setup_channel_provider)
    end
  end
end
