require 'rails_helper'

describe Integrations::Slack::SendContactUpdateService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, email: 'new@example.com') }
  let(:inbox) { create(:inbox, account: account) }
  let!(:slack_conversation) do
    create(:conversation, account: account, inbox: inbox, contact: contact, identifier: '12345.6789', status: :open)
  end
  let!(:hook) { create(:integrations_hook, app_id: 'slack', account: account) }
  let(:slack_client) { instance_double(Slack::Web::Client) }
  let(:service) { described_class.new(contact: contact, hook: hook, changed_attributes: changed_attributes) }

  before do
    allow(service).to receive(:slack_client).and_return(slack_client)
  end

  context 'when the email is being added for the first time' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    it 'posts a thread message announcing the new email' do
      expect(slack_client).to receive(:chat_postMessage).with(
        channel: hook.reference_id,
        text: a_string_including('new@example.com').and(a_string_including('added')),
        thread_ts: slack_conversation.identifier,
        unfurl_links: false
      )

      service.perform
    end
  end

  context 'when the email is being changed' do
    let(:changed_attributes) { { 'email' => ['old@example.com', 'new@example.com'] } }

    it 'posts a thread message showing the old and new emails' do
      expect(slack_client).to receive(:chat_postMessage).with(
        hash_including(
          channel: hook.reference_id,
          text: a_string_including('old@example.com').and(a_string_including('new@example.com')),
          thread_ts: slack_conversation.identifier,
          unfurl_links: false
        )
      )

      service.perform
    end
  end

  context 'when the contact has no email' do
    let(:changed_attributes) { { 'email' => ['old@example.com', nil] } }

    it 'is a no-op' do
      contact.update!(email: nil)

      expect(slack_client).not_to receive(:chat_postMessage)
      service.perform
    end
  end

  context 'when the contact has no conversations linked to a Slack thread' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    it 'is a no-op' do
      slack_conversation.update!(identifier: nil)

      expect(slack_client).not_to receive(:chat_postMessage)
      service.perform
    end
  end

  context 'when a conversation identifier is not a Slack thread timestamp' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    it 'skips conversations whose identifier comes from another channel (e.g. a Twilio call SID)' do
      slack_conversation.update!(identifier: 'CA9f2cb8d9876f1a23b45c6789d0ef1234')

      expect(slack_client).not_to receive(:chat_postMessage)
      service.perform
    end
  end

  context 'when the conversation is resolved' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    it 'skips resolved conversations' do
      slack_conversation.update!(status: :resolved)

      expect(slack_client).not_to receive(:chat_postMessage)
      service.perform
    end
  end

  context 'when posting against multiple active conversations' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    before do
      create(:conversation, account: account, inbox: inbox, contact: contact, identifier: '99999.1111', status: :pending)
    end

    it 'posts an update in each thread' do
      expect(slack_client).to receive(:chat_postMessage)
        .with(hash_including(thread_ts: '12345.6789')).once
      expect(slack_client).to receive(:chat_postMessage)
        .with(hash_including(thread_ts: '99999.1111')).once

      service.perform
    end
  end

  context 'when Slack returns an auth error' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    before do
      create(:conversation, account: account, inbox: inbox, contact: contact, identifier: '99999.1111', status: :pending)
      allow(slack_client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::InvalidAuth.new('invalid_auth'))
      allow(hook).to receive(:prompt_reauthorization!)
    end

    it 'disables the hook and prompts reauthorization' do
      expect { service.perform }.to change { hook.reload.disabled? }.from(false).to(true)
      expect(hook).to have_received(:prompt_reauthorization!)
    end

    it 'aborts after the first failure instead of repeating it for every conversation' do
      service.perform

      expect(slack_client).to have_received(:chat_postMessage).once
      expect(hook).to have_received(:prompt_reauthorization!).once
    end
  end

  context 'when Slack returns a transient error' do
    let(:changed_attributes) { { 'email' => [nil, 'new@example.com'] } }

    it 'continues posting to the remaining conversations' do
      create(:conversation, account: account, inbox: inbox, contact: contact, identifier: '99999.1111', status: :pending)
      call_count = 0
      allow(slack_client).to receive(:chat_postMessage) do
        call_count += 1
        raise Slack::Web::Api::Errors::SlackError, 'rate_limited' if call_count == 1
      end

      service.perform

      expect(slack_client).to have_received(:chat_postMessage).twice
      expect(hook.reload.disabled?).to be(false)
    end
  end
end
