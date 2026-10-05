require 'rails_helper'

RSpec.describe SlackPendingReplyJob do
  let(:account) { create(:account) }
  let!(:hook) { create(:integrations_hook, account: account, reference_id: 'C123') }
  let(:reference) { { 'channel' => 'C123', 'thread_ts' => '1700000000.000100', 'ts' => '1700000050.000200' } }
  let(:response_url) { 'https://hooks.slack.com/actions/T1/1/abc' }
  let(:reply) { { 'type' => 'message', 'user' => 'U1', 'text' => 'On it', 'ts' => reference['ts'], 'thread_ts' => reference['thread_ts'] } }
  let(:slack_client) { instance_double(Slack::Web::Client) }
  let(:builder) { instance_double(Integrations::Slack::IncomingMessageBuilder, perform: true) }

  before do
    stub_request(:post, response_url)
    allow(Slack::Web::Client).to receive(:new).with(token: hook.access_token).and_return(slack_client)
    allow(slack_client).to receive(:conversations_replies).and_return(Slack::Messages::Message.new(messages: [reply]))
    allow(Integrations::Slack::IncomingMessageBuilder).to receive(:new).and_return(builder)
  end

  it 'clears the prompt' do
    described_class.perform_now(reference, 'takeover', response_url)

    expect(WebMock).to have_requested(:post, response_url).with(body: { delete_original: true }.to_json)
  end

  it 'reads the held back reply from Slack and sends it with the confirmed action' do
    described_class.perform_now(reference, 'takeover', response_url)

    expect(slack_client).to have_received(:conversations_replies).with(
      channel: 'C123', ts: reference['thread_ts'], latest: reference['ts'], oldest: reference['ts'], inclusive: true, limit: 1
    )
    expect(Integrations::Slack::IncomingMessageBuilder).to have_received(:new).with(
      hash_including('type' => 'event_callback', 'confirmed_action' => 'takeover', 'event' => reply.merge('channel' => 'C123'))
    )
    expect(builder).to have_received(:perform)
  end

  it 'does not send anything when the reply was deleted in Slack' do
    allow(slack_client).to receive(:conversations_replies).and_return(Slack::Messages::Message.new(messages: []))

    described_class.perform_now(reference, 'takeover', response_url)

    expect(Integrations::Slack::IncomingMessageBuilder).not_to have_received(:new)
  end

  it 'does not send anything when Slack cannot return the reply' do
    allow(slack_client).to receive(:conversations_replies).and_raise(Slack::Web::Api::Errors::SlackError.new('thread_not_found'))

    described_class.perform_now(reference, 'takeover', response_url)

    expect(Integrations::Slack::IncomingMessageBuilder).not_to have_received(:new)
  end

  it 'does not send anything when the channel has no hook' do
    described_class.perform_now(reference.merge('channel' => 'C999'), 'takeover', response_url)

    expect(Integrations::Slack::IncomingMessageBuilder).not_to have_received(:new)
  end
end
