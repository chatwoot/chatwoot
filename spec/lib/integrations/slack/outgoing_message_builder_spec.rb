require 'rails_helper'

describe Integrations::Slack::OutgoingMessageBuilder do
  let(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact) }

  let!(:hook) { create(:integrations_hook, account: account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let!(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  describe '#perform' do
    it 'sent message to slack' do
      builder = described_class.new(hook, message)
      stub_request(:post, 'https://slack.com/api/chat.postMessage')
        .to_return(status: 200, body: '', headers: {})

      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Slack::Web::Client).to receive(:chat_postMessage).with(
        channel: hook.reference_id,
        text: message.content,
        username: contact.name,
        thread_ts: conversation.identifier
      )
      # rubocop:enable RSpec/AnyInstance

      builder.perform
    end
  end
end
