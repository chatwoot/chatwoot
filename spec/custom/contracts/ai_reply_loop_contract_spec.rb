require 'rails_helper'

# Locks the upstream contracts the external AI orchestrator depends on
# (docs/fork/AI_REPLY_LOOP.md). If any of these fail after an upstream merge,
# the AI loop breaks even though nothing in custom/ changed.
RSpec.describe 'AI reply loop contract', type: :request do
  let(:account) { create(:account) }

  it 'keeps the webhook events the loop subscribes to' do
    expect(Webhook::ALLOWED_WEBHOOK_EVENTS).to include('message_created', 'message_updated')
  end

  it 'keeps the loop-prevention fields in the message webhook payload' do
    conversation = create(:conversation, account: account)
    message = create(:message, account: account, conversation: conversation, message_type: :incoming)

    payload = message.webhook_data

    expect(payload).to include(:id, :content, :message_type, :private, :sender, :source_id, :created_at)
    expect(payload[:message_type]).to eq('incoming')
    expect(payload[:account][:id]).to eq(account.id)
    expect(payload[:conversation]).to be_present
  end

  it 'signs webhook deliveries with the HMAC recipe the orchestrator implements' do
    captured_headers = nil
    allow(SafeFetch).to receive(:fetch) do |_url, **options|
      captured_headers = options[:headers]
      instance_double(SafeFetch::Result)
    end

    Webhooks::Trigger.execute('https://orchestrator.example.com/ingest', { event: 'message_created' },
                              :account_webhook, secret: 'tenant-secret', delivery_id: 'delivery-1')

    timestamp = captured_headers['X-Chatwoot-Timestamp']
    body = { event: 'message_created' }.to_json
    expect(timestamp).to match(/\A\d+\z/)
    expect(captured_headers['X-Chatwoot-Signature'])
      .to eq("sha256=#{OpenSSL::HMAC.hexdigest('SHA256', 'tenant-secret', "#{timestamp}.#{body}")}")
    expect(captured_headers['X-Chatwoot-Delivery']).to eq('delivery-1')
  end

  it 'lets an agent bot post an outgoing reply through the message API' do
    agent_bot = create(:agent_bot, account: account)
    conversation = create(:conversation, account: account)
    create(:agent_bot_inbox, agent_bot: agent_bot, inbox: conversation.inbox)

    post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
         params: { content: 'AI reply', message_type: 'outgoing' },
         headers: { api_access_token: agent_bot.access_token.token }, as: :json

    expect(response).to have_http_status(:success)
    message = conversation.messages.last
    expect(message.content).to eq('AI reply')
    expect(message.message_type).to eq('outgoing')
  end
end
