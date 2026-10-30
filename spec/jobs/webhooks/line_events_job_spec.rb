require 'rails_helper'

RSpec.describe Webhooks::LineEventsJob do
  subject(:job) { described_class.perform_later(params: params) }

  let!(:line_channel) { create(:channel_line) }
  let!(:params) { { :line_channel_id => line_channel.line_channel_id, 'line' => { test: 'test' } } }
  let(:post_body) { params.to_json }
  let(:signature) { Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('SHA256'), line_channel.line_channel_secret, post_body)) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params: params)
      .on_queue('default')
  end

  context 'when invalid params' do
    it 'returns nil when no line_channel_id' do
      expect(described_class.perform_now(params: {})).to be_nil
    end

    it 'returns nil when invalid bot_token' do
      expect(described_class.perform_now(params: { 'line_channel_id' => 'invalid_id', 'line' => { test: 'test' } })).to be_nil
    end
  end

  context 'when valid params' do
    it 'calls Line::IncomingMessageService' do
      process_service = double
      allow(Line::IncomingMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)
      expect(Line::IncomingMessageService).to receive(:new).with(inbox: line_channel.inbox,
                                                                 params: params['line'].with_indifferent_access)
      expect(process_service).to receive(:perform)
      described_class.perform_now(params: params, post_body: post_body, signature: signature)
    end

    it 'attempts to acquire a lock and then processes the message' do
      process_service = double
      allow(Line::IncomingMessageService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)

      lock_key = format(Redis::Alfred::LINE_MESSAGE_MUTEX, line_channel_id: line_channel.line_channel_id)
      job_instance = described_class.new
      allow(job_instance).to receive(:with_lock).and_call_original

      job_instance.perform(params: params, post_body: post_body, signature: signature)

      expect(job_instance).to have_received(:with_lock).with(lock_key, 10.seconds)
      expect(process_service).to have_received(:perform)
    end
  end
end
