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

  context 'when updates from the same chat arrive concurrently' do
    let(:update_type) { 'message' }
    let(:first_update) do
      { :bot_token => telegram_channel.bot_token, 'telegram' => { update_type => { 'message_id' => 1, 'chat' => { 'id' => 23 } } } }
    end
    let(:same_chat_update) do
      { :bot_token => telegram_channel.bot_token, 'telegram' => { update_type => { 'message_id' => 2, 'chat' => { 'id' => 23 } } } }
    end
    let(:other_chat_update) do
      { :bot_token => telegram_channel.bot_token, 'telegram' => { update_type => { 'message_id' => 3, 'chat' => { 'id' => 24 } } } }
    end
    let(:concurrent_update) { same_chat_update }
    let(:process_service) { instance_double(Telegram::IncomingMessageService) }
    let(:processed_message_ids) { [] }

    before do
      allow(Telegram::IncomingMessageService).to receive(:new) do |args|
        processed_message_ids << args[:params].dig(update_type, :message_id)
        process_service
      end
      allow(process_service).to receive(:perform) do
        described_class.perform_now(concurrent_update.with_indifferent_access) if processed_message_ids.one?
      end
    end

    it 'retries the second update instead of processing it while the first is in progress' do
      expect { described_class.perform_now(first_update.with_indifferent_access) }.to have_enqueued_job(described_class).exactly(:once)

      expect(processed_message_ids).to eq([1])
    end

    context 'when the updates are business messages' do
      let(:update_type) { 'business_message' }

      it 'retries the second update instead of processing it while the first is in progress' do
        expect { described_class.perform_now(first_update.with_indifferent_access) }.to have_enqueued_job(described_class).exactly(:once)

        expect(processed_message_ids).to eq([1])
      end
    end

    context 'when the concurrent update is from another chat' do
      let(:concurrent_update) { other_chat_update }

      it 'processes it without waiting for the first update' do
        expect { described_class.perform_now(first_update.with_indifferent_access) }.not_to have_enqueued_job(described_class)

        expect(processed_message_ids).to eq([1, 3])
      end
    end
  end
end
