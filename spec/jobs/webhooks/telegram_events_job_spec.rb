require 'rails_helper'

RSpec.describe Webhooks::TelegramEventsJob, type: :job do
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

    it 'returns nil when invalid bot_token' do
      expect(described_class.perform_now({ bot_token: 'invalid' })).to be_nil
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
      described_class.perform_now(params)
    end
  end
end
