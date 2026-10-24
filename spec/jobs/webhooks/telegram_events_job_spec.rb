require 'rails_helper'

RSpec.describe Webhooks::TelegramEventsJob do
  subject(:job) { described_class.perform_later(params) }

  let!(:telegram_channel) { create(:channel_telegram) }
  let!(:params) { { :bot_token => telegram_channel.bot_token, 'telegram' => { test: 'test' } } }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('default')
  end

  context 'when invalid params' do
    it 'returns nil when no bot_token' do
      expect(described_class.perform_now({})).to be_nil
    end

    it 'logs a warning when channel is not found' do
      expect(Rails.logger).to receive(:warn).with('Telegram event discarded: Channel not found for bot_token: invalid')
      described_class.perform_now({ bot_token: 'invalid' })
    end
  end

  context 'when valid params' do
    it 'calls Telegram::IncomingMessageService' do
      process_service = double
      allow(Telegram::IncomingMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)
      expect(Telegram::IncomingMessageService).to receive(:new).with(inbox: telegram_channel.inbox,
                                                                     params: params['telegram'].with_indifferent_access)
      expect(process_service).to receive(:perform)
      described_class.perform_now(params.with_indifferent_access)
    end

    it 'processes a business connection update from a symbol-keyed payload' do
      connection = { id: 'connection-1', is_enabled: true }
      business_connection_service = instance_double(Telegram::BusinessConnectionService, observe_update: nil, process: nil)
      business_params = { bot_token: telegram_channel.bot_token, telegram: { update_id: 42, business_connection: connection } }

      allow(Telegram::BusinessConnectionService).to receive(:new).with(channel: telegram_channel).and_return(business_connection_service)
      expect(business_connection_service).to receive(:process).with(connection.with_indifferent_access, update_id: 42).ordered
      expect(business_connection_service).to receive(:observe_update).with(42).ordered
      expect(Telegram::IncomingMessageService).not_to receive(:new)

      described_class.perform_now(business_params)
    end

    it 'syncs a business connection before processing a business message' do
      business_connection_service = instance_double(Telegram::BusinessConnectionService, observe_update: nil, sync: nil)
      incoming_message_service = instance_double(Telegram::IncomingMessageService, perform: nil)
      telegram_params = { update_id: 42, business_message: { business_connection_id: 'connection-1' } }
      business_params = { bot_token: telegram_channel.bot_token }
      business_params['telegram'] = telegram_params

      allow(Telegram::BusinessConnectionService).to receive(:new).with(channel: telegram_channel).and_return(business_connection_service)
      allow(Telegram::IncomingMessageService).to receive(:new)
        .with(inbox: telegram_channel.inbox, params: telegram_params.with_indifferent_access)
        .and_return(incoming_message_service)

      expect(business_connection_service).to receive(:sync).with('connection-1', update_id: 42).ordered
      expect(incoming_message_service).to receive(:perform).ordered
      expect(business_connection_service).to receive(:observe_update).with(42).ordered.and_raise(StandardError, 'lock timeout')
      expect(Rails.logger).to receive(:error)
        .with("Failed to record Telegram update ID for channel #{telegram_channel.id}: lock timeout")
        .ordered

      described_class.perform_now(business_params)
    end

    it 'logs a warning and does not process events if account is suspended' do
      account = telegram_channel.account
      account.update!(status: :suspended)

      process_service = double
      allow(Telegram::IncomingMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)

      expect(Rails.logger).to receive(:warn).with("Telegram event discarded: Account #{account.id} is not active for channel #{telegram_channel.id}")
      expect(Telegram::IncomingMessageService).not_to receive(:new)
      described_class.perform_now(params.with_indifferent_access)
    end
  end

  context 'when update message params' do
    let!(:params) { { :bot_token => telegram_channel.bot_token, 'telegram' => { edited_message: 'test' } } }

    it 'calls Telegram::UpdateMessageService' do
      process_service = double
      allow(Telegram::UpdateMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)
      expect(Telegram::UpdateMessageService).to receive(:new).with(inbox: telegram_channel.inbox,
                                                                   params: params['telegram'].with_indifferent_access)
      expect(process_service).to receive(:perform)
      described_class.perform_now(params.with_indifferent_access)
    end
  end
end
