require 'rails_helper'

RSpec.describe Webhooks::WhatsappEventsJob do
  subject(:job) { described_class }

  let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false) }
  let(:params)  do
    {
      object: 'whatsapp_business_account',
      phone_number: channel.phone_number,
      entry: [{
        changes: [
          {
            value: {
              metadata: {
                phone_number_id: channel.provider_config['phone_number_id'],
                display_phone_number: channel.phone_number.delete('+')
              }
            }
          }
        ]
      }]
    }
  end
  let(:process_service) { double }

  before do
    allow(process_service).to receive(:perform)
  end

  it 'enqueues the job' do
    expect { job.perform_later(params) }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('low')
  end

  context 'when whatsapp_cloud provider' do
    it 'enqueue Whatsapp::IncomingMessageWhatsappCloudService' do
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new)
      job.perform_now(params)
    end

    it 'will not enqueue message jobs based on phone number in the URL if the entry payload is not present' do
      params = {
        object: 'whatsapp_business_account',
        phone_number: channel.phone_number,
        entry: [{ changes: [{}] }]
      }
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new)
      allow(Whatsapp::IncomingMessageService).to receive(:new)

      expect(Whatsapp::IncomingMessageWhatsappCloudService).not_to receive(:new)
      expect(Whatsapp::IncomingMessageService).not_to receive(:new)
      job.perform_now(params)
    end

    it 'will not enqueue Whatsapp::IncomingMessageWhatsappCloudService if channel reauthorization required' do
      channel.prompt_reauthorization!
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageWhatsappCloudService).not_to receive(:new)
      job.perform_now(params)
    end

    it 'still enqueues for manual channels even when reauthorization required' do
      channel.update!(provider_config: channel.provider_config.merge('source' => 'manual'))
      channel.prompt_reauthorization!
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new)
      job.perform_now(params)
    end

    it 'will not enqueue if channel is not present' do
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      allow(Whatsapp::IncomingMessageService).to receive(:new).and_return(process_service)

      expect(Whatsapp::IncomingMessageWhatsappCloudService).not_to receive(:new)
      expect(Whatsapp::IncomingMessageService).not_to receive(:new)
      job.perform_now(phone_number: 'random_phone_number')
    end

    it 'will not enqueue Whatsapp::IncomingMessageWhatsappCloudService if account is suspended' do
      account = channel.account
      account.update!(status: :suspended)
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      allow(Whatsapp::IncomingMessageService).to receive(:new).and_return(process_service)

      expect(Whatsapp::IncomingMessageWhatsappCloudService).not_to receive(:new)
      expect(Whatsapp::IncomingMessageService).not_to receive(:new)
      job.perform_now(params)
    end

    it 'logs a warning when channel is inactive' do
      channel.prompt_reauthorization!
      allow(Rails.logger).to receive(:warn)

      expect(Rails.logger).to receive(:warn).with("Inactive WhatsApp channel: #{channel.phone_number}")
      job.perform_now(params)
    end

    it 'logs a warning with unknown phone number when channel does not exist' do
      unknown_phone = '+1234567890'
      allow(Rails.logger).to receive(:warn)

      expect(Rails.logger).to receive(:warn).with("Inactive WhatsApp channel: unknown - #{unknown_phone}")
      job.perform_now(phone_number: unknown_phone)
    end

    it 'uses from_user_id as the mutex sender for BSUID-only inbound messages' do
      bsuid = 'IN.2081978709342942'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:value][:messages] = [
        { from: '', from_user_id: bsuid, id: 'wamid-test', text: { body: 'Hello' }, type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'prefers from_user_id as the mutex sender for mixed phone and BSUID inbound messages' do
      bsuid = 'IN.2081978709342942'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:value][:messages] = [
        { from: '919745786257', from_user_id: bsuid, id: 'wamid-test', text: { body: 'Hello' }, type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'uses contact user_id as the mutex sender when message from_user_id is missing' do
      bsuid = 'IN.2081978709342942'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:value][:contacts] = [
        { profile: { name: 'Muhsin' }, wa_id: '919745786257', user_id: bsuid }
      ]
      wb_params[:entry].first[:changes].first[:value][:messages] = [
        { from: '919745786257', id: 'wamid-test', text: { body: 'Hello' }, type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'prefers parent BSUID as the mutex sender for inbound messages with both identifiers' do
      bsuid = 'IN.2081978709342942'
      parent_bsuid = 'IN.ENT.9081726354'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:value][:contacts] = [
        { profile: { name: 'Muhsin' }, user_id: bsuid, parent_user_id: parent_bsuid }
      ]
      wb_params[:entry].first[:changes].first[:value][:messages] = [
        { from_user_id: bsuid, from_parent_user_id: parent_bsuid, id: 'wamid-test', text: { body: 'Hello' }, type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: parent_bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'uses to_user_id as the mutex sender for BSUID-only echo messages' do
      bsuid = 'IN.2081978709342942'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:field] = 'smb_message_echoes'
      wb_params[:entry].first[:changes].first[:value][:message_echoes] = [
        { from: channel.phone_number.delete('+'), to: '', to_user_id: bsuid, id: 'wamid-test', text: { body: 'Hello' }, type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'prefers parent BSUID as the mutex sender for echo messages with both identifiers' do
      bsuid = 'IN.2081978709342942'
      parent_bsuid = 'IN.ENT.9081726354'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:field] = 'smb_message_echoes'
      wb_params[:entry].first[:changes].first[:value][:message_echoes] = [
        {
          from: channel.phone_number.delete('+'), to: '919745786257', to_user_id: bsuid, to_parent_user_id: parent_bsuid,
          id: 'wamid-test', text: { body: 'Hello' }, type: 'text'
        }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: parent_bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end

    it 'prefers to_user_id as the mutex sender for mixed phone and BSUID echo messages' do
      bsuid = 'IN.2081978709342942'
      wb_params = params.deep_dup
      wb_params[:entry].first[:changes].first[:field] = 'smb_message_echoes'
      wb_params[:entry].first[:changes].first[:value][:message_echoes] = [
        { from: channel.phone_number.delete('+'), to: '919745786257', to_user_id: bsuid, id: 'wamid-test', text: { body: 'Hello' },
          type: 'text' }
      ]
      job_instance = described_class.new
      mutex_key = format(Redis::Alfred::WHATSAPP_MESSAGE_MUTEX, inbox_id: channel.inbox.id, sender_id: bsuid)

      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(job_instance).to receive(:with_lock).with(mutex_key, 30.seconds).and_yield

      job_instance.perform(wb_params)
    end
  end

  context 'when Coexistence history-sync events' do
    let(:history_params) do
      wb = params.deep_dup
      wb[:entry].first[:changes].first[:field] = 'history'
      wb[:entry].first[:changes].first[:value][:history] = [{ metadata: { phase: 0 }, threads: [] }]
      wb
    end
    let(:state_sync_params) do
      wb = params.deep_dup
      wb[:entry].first[:changes].first[:field] = 'smb_app_state_sync'
      wb[:entry].first[:changes].first[:value][:state_sync] = []
      wb
    end

    it 'routes history webhooks to Whatsapp::HistoryMessageService when the flag is on' do
      # Reason: history payloads must reach the dedicated importer, not the live message pipeline.
      allow(Whatsapp::HistoryMessageService).to receive(:new).and_return(process_service)
      with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
        expect(Whatsapp::HistoryMessageService).to receive(:new).with(inbox: channel.inbox, params: history_params)
        job.perform_now(history_params)
      end
    end

    it 'acquires and releases the per-inbox history-sync lock around a normal import' do
      # Reason: the lock now lives at the job layer (moved out of the service) so a conflict
      # raises LockAcquisitionError and is retried by ActiveJob instead of silently skipping.
      lock_key = format(Redis::Alfred::WHATSAPP_HISTORY_SYNC_MUTEX, inbox_id: channel.inbox.id)
      allow(Whatsapp::HistoryMessageService).to receive(:new).and_return(process_service)

      with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
        expect(Redis::LockManager.new.locked?(lock_key)).to be false
        job.perform_now(history_params)
        expect(Redis::LockManager.new.locked?(lock_key)).to be false
      end
      expect(process_service).to have_received(:perform)
    end

    context 'when a history import is already in progress for the channel' do
      let(:lock_key) { format(Redis::Alfred::WHATSAPP_HISTORY_SYNC_MUTEX, inbox_id: channel.inbox.id) }

      after { Redis::Alfred.delete(lock_key) }

      it 'raises LockAcquisitionError instead of skipping the chunk, so ActiveJob retries it' do
        # Reason: the webhook already returned 200 to Meta, which will not re-deliver on 2xx.
        # A silent skip here would permanently lose the chunk; raising lets `retry_on` in this
        # job re-attempt until the holder releases the lock.
        expect(Redis::LockManager.new.lock(lock_key, 5.minutes)).to be true
        allow(Whatsapp::HistoryMessageService).to receive(:new)

        with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
          expect do
            job.new.perform(history_params)
          end.to raise_error(MutexApplicationJob::LockAcquisitionError)
        end
        expect(Whatsapp::HistoryMessageService).not_to have_received(:new)
      end
    end

    it 'routes smb_app_state_sync webhooks to Whatsapp::ContactStateSyncService when the flag is on' do
      # Reason: contact-roster payloads seed/update contacts via their own handler.
      allow(Whatsapp::ContactStateSyncService).to receive(:new).and_return(process_service)
      with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
        expect(Whatsapp::ContactStateSyncService).to receive(:new).with(inbox: channel.inbox, params: state_sync_params)
        job.perform_now(state_sync_params)
      end
    end

    it 'ignores history webhooks (no handler) when the flag is off' do
      # Reason: flag off means the pipeline is inert even if a webhook slips through.
      allow(Whatsapp::HistoryMessageService).to receive(:new)
      expect(Whatsapp::HistoryMessageService).not_to receive(:new)
      job.perform_now(history_params)
    end
  end

  context 'when Enterprise calls overlay is present' do
    let(:calls_params) do
      wb = params.deep_dup
      wb[:entry].first[:changes].first[:field] = 'calls'
      wb[:entry].first[:changes].first[:value][:calls] = [{ id: 'call_1', event: 'connect' }]
      wb
    end

    it 'still routes calls events to the Enterprise call handler (history routing did not break it)' do
      # Reason: new history routing sits before message handling and must not swallow `calls` events.
      allow(Whatsapp::IncomingCallService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingCallService).to receive(:new)
      job.perform_now(calls_params)
    end
  end

  context 'when default provider' do
    it 'enqueue Whatsapp::IncomingMessageService' do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      channel.update(provider: 'default')
      allow(Whatsapp::IncomingMessageService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageService).to receive(:new)
      job.perform_now(params)
    end
  end

  context 'when whatsapp business params' do
    it 'enqueue Whatsapp::IncomingMessageWhatsappCloudService based on the number in payload' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: {
                    phone_number_id: other_channel.provider_config['phone_number_id'],
                    display_phone_number: other_channel.phone_number.delete('+')
                  }
                }
              }
            ]
          }
        ]
      }
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).with(inbox: other_channel.inbox, params: wb_params)
      job.perform_now(wb_params)
    end

    it 'Ignore reaction type message and stop raising error' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Test Test' }, wa_id: '1111981136571' }],
              messages: [{
                from: '1111981136571', reaction: { emoji: '👍' }, timestamp: '1664799904', type: 'reaction'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Message, :count)
    end

    it 'ignore reaction type message, would not create contact if the reaction is the first event' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              contacts: [{ profile: { name: 'Test Test' }, wa_id: '1111981136571' }],
              messages: [{
                from: '1111981136571', reaction: { emoji: '👍' }, timestamp: '1664799904', type: 'reaction'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Contact, :count)
    end

    it 'ignore request_welcome type message, would not create contact or conversation' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [{
          changes: [{
            value: {
              messages: [{
                from: '1111981136571', timestamp: '1664799904', type: 'request_welcome'
              }],
              metadata: {
                phone_number_id: other_channel.provider_config['phone_number_id'],
                display_phone_number: other_channel.phone_number.delete('+')
              }
            }
          }]
        }]
      }.with_indifferent_access
      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Contact, :count)

      expect do
        Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: other_channel.inbox, params: wb_params).perform
      end.not_to change(Conversation, :count)
    end

    it 'will not enque Whatsapp::IncomingMessageWhatsappCloudService when invalid phone number id' do
      other_channel = create(:channel_whatsapp, phone_number: '+1987654', provider: 'whatsapp_cloud', sync_templates: false,
                                                validate_provider_config: false)
      wb_params = {
        phone_number: channel.phone_number,
        object: 'whatsapp_business_account',
        entry: [
          {
            changes: [
              {
                value: {
                  metadata: {
                    phone_number_id: 'random phone number id',
                    display_phone_number: other_channel.phone_number.delete('+')
                  }
                }
              }
            ]
          }
        ]
      }
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_return(process_service)
      expect(Whatsapp::IncomingMessageWhatsappCloudService).not_to receive(:new).with(inbox: other_channel.inbox, params: wb_params)
      job.perform_now(wb_params)
    end
  end
end
