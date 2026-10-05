require 'rails_helper'

describe Integrations::Slack::SendOnSlackService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, identifier: 'random_slack_thread_ts') }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:message) do
    create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :outgoing,
                     sender: create(:captain_assistant, account: account))
  end
  let(:slack_client) { instance_double(Slack::Web::Client) }
  let(:builder) { described_class.new(message: message, hook: hook) }

  before { allow(builder).to receive(:slack_client).and_return(slack_client) }

  context 'when the message is sent by Captain' do
    it 'labels the sender as Captain and uses the Captain avatar' do
      expect(slack_client).to receive(:chat_postMessage).with(
        hash_including(username: "#{message.sender.name} (Captain)", icon_url: a_string_ending_with('sender_type=captain_avatar'))
      ).and_return({ 'ts' => '12345.6789', 'message' => { 'ts' => '6789.12345', 'thread_ts' => '12345.6789' } })

      builder.perform
    end
  end
end
