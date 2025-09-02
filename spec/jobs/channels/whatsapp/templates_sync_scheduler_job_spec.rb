require 'rails_helper'

RSpec.describe Channels::Whatsapp::TemplatesSyncSchedulerJob do
  # Add WebMock stubs for WhatsApp 360Dialog API calls to prevent external requests during tests
  before do
    # Stub 360Dialog webhook configuration API call
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '', headers: {})
    
    # Stub 360Dialog templates API call - this was missing and causing the test failures
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: '{"waba_templates": []}', headers: { 'Content-Type' => 'application/json' })
  end

  it 'enqueues the job' do
    expect { described_class.perform_later }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when called' do
    it 'schedules templates_sync_jobs for channels where templates need to be updated' do
      non_synced = create(:channel_whatsapp, sync_templates: false)
      synced_recently = create(:channel_whatsapp, sync_templates: false)
      synced_old = create(:channel_whatsapp, sync_templates: false)
      
      # Manually set the message_templates_last_updated values after creation to avoid callback interference
      non_synced.update_column(:message_templates_last_updated, nil)
      synced_recently.update_column(:message_templates_last_updated, Time.zone.now)
      synced_old.update_column(:message_templates_last_updated, 4.hours.ago)
      
      described_class.perform_now
      expect(Channels::Whatsapp::TemplatesSyncJob).not_to(
        have_been_enqueued.with(synced_recently).on_queue('low')
      )
      expect(Channels::Whatsapp::TemplatesSyncJob).to(
        have_been_enqueued.with(synced_old).on_queue('low')
      )
      expect(Channels::Whatsapp::TemplatesSyncJob).to(
        have_been_enqueued.with(non_synced).on_queue('low')
      )
    end

    it 'schedules templates_sync_job for oldest synced channels first' do
      stub_const('Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT', 2)
      non_synced = create(:channel_whatsapp, sync_templates: false)
      synced_recently = create(:channel_whatsapp, sync_templates: false)
      synced_old = create(:channel_whatsapp, sync_templates: false)
      
      # Manually set the message_templates_last_updated values after creation to avoid callback interference
      non_synced.update_column(:message_templates_last_updated, nil)
      synced_recently.update_column(:message_templates_last_updated, 4.hours.ago)
      synced_old.update_column(:message_templates_last_updated, 6.hours.ago)
      
      described_class.perform_now
      expect(Channels::Whatsapp::TemplatesSyncJob).not_to(
        have_been_enqueued.with(synced_recently).on_queue('low')
      )
      expect(Channels::Whatsapp::TemplatesSyncJob).to(
        have_been_enqueued.with(synced_old).on_queue('low')
      )
      expect(Channels::Whatsapp::TemplatesSyncJob).to(
        have_been_enqueued.with(non_synced).on_queue('low')
      )
    end
  end
end
