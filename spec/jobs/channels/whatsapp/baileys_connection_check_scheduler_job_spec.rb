require 'rails_helper'

RSpec.describe Channels::Whatsapp::BaileysConnectionCheckSchedulerJob do
  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'schedules BaileysConnectionCheckJob for each WhatsApp channel with baileys provider connection open' do
      channel = create(:channel_whatsapp, provider: 'baileys', provider_connection: { 'connection' => 'open' }, sync_templates: false,
                                          validate_provider_config: false)

      described_class.perform_now

      expect(Channels::Whatsapp::BaileysConnectionCheckJob).to have_been_enqueued.with(channel).on_queue('low')
    end

    it 'does not schedule BaileysConnectionCheckJob for channels with different provider' do
      create(:channel_whatsapp, provider: 'whatsapp_cloud', provider_connection: { 'connection' => 'open' }, sync_templates: false,
                                validate_provider_config: false)

      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(Channels::Whatsapp::BaileysConnectionCheckJob)
    end

    it 'does not schedule BaileysConnectionCheckJob for channels with closed connection' do
      create(:channel_whatsapp, provider: 'baileys', provider_connection: { 'connection' => 'closed' }, sync_templates: false,
                                validate_provider_config: false)

      expect do
        described_class.perform_now
      end.not_to have_enqueued_job(Channels::Whatsapp::BaileysConnectionCheckJob)
    end
  end
end
