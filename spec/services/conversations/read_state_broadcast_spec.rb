require 'rails_helper'

RSpec.describe Conversations::ReadStateBroadcast do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:seller) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, read_baseline_at: 1.hour.ago) }
  let(:tokens) { [admin.pubsub_token, seller.pubsub_token, conversation.contact_inbox.pubsub_token] }
  let(:service) { described_class.new(conversation: conversation) }

  before do
    create(:message, conversation: conversation, account: account, message_type: :incoming, created_at: 1.minute.ago)
    ConversationReadState.create!(account: account, conversation: conversation, user: admin, last_seen_at: Time.current)
  end

  it 'personalizes conversation events and preserves the external contact payload' do
    payload = { id: conversation.display_id, unread_count: 0, agent_last_seen_at: Time.current.to_i }
    result = service.payloads(tokens, payload)
    expect(result.find { |recipients, _| recipients.include?(admin.pubsub_token) }.last[:unread_count]).to eq(0)
    expect(result.find { |recipients, _| recipients.include?(seller.pubsub_token) }.last[:unread_count]).to eq(1)
    expect(result.find { |recipients, _| recipients.include?(conversation.contact_inbox.pubsub_token) }.last).to eq(payload)
  end

  it 'personalizes the nested conversation inside message events' do
    payload = { id: 999, conversation: { unread_count: 0, assignee_id: seller.id } }
    result = service.payloads(tokens, payload, nested: true)
    seller_payload = result.find { |recipients, _| recipients.include?(seller.pubsub_token) }.last
    expect(seller_payload).to include(id: 999)
    expect(seller_payload[:conversation]).to include(assignee_id: seller.id, unread_count: 1)
    expect(payload[:conversation][:unread_count]).to eq(0)
  end

  it 'batches receipt lookups rather than querying separately for each recipient' do
    extra = create(:user, account: account, role: :agent)
    result = service.payloads(tokens + [extra.pubsub_token], { id: conversation.display_id })
    shared = result.find { |recipients, _| recipients.include?(seller.pubsub_token) }
    expect(shared.first).to contain_exactly(seller.pubsub_token, extra.pubsub_token)
  end
end
