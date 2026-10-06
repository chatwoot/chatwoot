require 'rails_helper'

RSpec.describe ConversationMonitors::SlackAlertService do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:monitor) do
    create(:conversation_monitor, account: account, name: 'Refunds', condition: 'Customer asks for a <refund> & is upset',
                                  slack_channel_id: 'C0ALERTS')
  end
  let(:contact) { create(:contact, account: account, name: 'Jane Doe') }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:slack_client) { instance_double(Slack::Web::Client, chat_postMessage: true, conversations_join: true) }
  let(:service) { described_class.new(monitor: monitor, conversation: conversation, hook: hook) }

  before do
    allow(Slack::Web::Client).to receive(:new).with(token: hook.access_token).and_return(slack_client)
    create(:message, account: account, conversation: conversation, message_type: :incoming, content: "I want my money back\nNow")
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched', score: 0.92)
  end

  it 'posts a block message describing the match to the monitor channel' do
    service.perform

    expect(slack_client).to have_received(:chat_postMessage) do |payload|
      expect(payload).to include(channel: 'C0ALERTS', text: 'Monitor matched: Refunds', unfurl_links: false)
      blocks = payload[:blocks]
      url = "/app/accounts/#{account.id}/conversations/#{conversation.display_id}"
      expect(blocks.pluck(:type)).to eq(%w[header context section section divider context])
      expect(blocks[0][:text][:text]).to eq('🔔 Refunds')
      expect(blocks[1][:elements].first[:text]).to start_with('Monitor matched · <!date^')
      expect(blocks[2][:text][:text]).to match(
        /\A\*<.*#{url}\|Conversation ##{conversation.display_id}>\* with Jane Doe\n> I want my money back\n> Now\z/
      )
    end
  end

  it 'lists the conversation details and the monitor condition' do
    service.perform

    expect(slack_client).to have_received(:chat_postMessage) do |payload|
      blocks = payload[:blocks]
      expect(blocks[3][:fields].pluck(:text)).to eq(
        ["*Inbox*\n#{conversation.inbox.name}", "*Assignee*\nUnassigned", "*Status*\nOpen", "*Confidence*\n92%"]
      )
      expect(blocks[5][:elements].first[:text]).to eq('*Condition:* Customer asks for a &lt;refund&gt; &amp; is upset')
    end
  end

  it 'uses the monitor emoji in the header and skips the quote when the customer has not written anything' do
    monitor.update!(icon: '🔥')
    conversation.messages.destroy_all

    service.perform

    expect(slack_client).to have_received(:chat_postMessage) do |payload|
      expect(payload[:blocks][0][:text][:text]).to eq('🔥 Refunds')
      expect(payload[:blocks][2][:text][:text]).to end_with('with Jane Doe')
    end
  end

  it 'joins the channel and retries when the app is not a member' do
    attempts = 0
    allow(slack_client).to receive(:chat_postMessage) do
      attempts += 1
      raise Slack::Web::Api::Errors::NotInChannel, 'not_in_channel' if attempts == 1
    end

    service.perform

    expect(slack_client).to have_received(:conversations_join).with(channel: 'C0ALERTS')
    expect(attempts).to eq(2)
  end
end
