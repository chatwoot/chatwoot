require 'rails_helper'

RSpec.describe ConversationMonitors::ContextBuilder do
  subject(:state) { described_class.new(conversation).build }

  let(:conversation) { create(:conversation) }
  let(:account) { conversation.account }

  it 'includes public evidence and excludes private notes, activity and deleted messages' do
    create(:message, conversation: conversation, account: account, content: '<p>A refund please</p>')
    create(:message, :outgoing, conversation: conversation, account: account, content: 'I can help')
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Private secret', private: true)
    create(:message, conversation: conversation, account: account, content: 'Old secret', content_attributes: { deleted: true })
    create(:message, conversation: conversation, account: account, content: 'Activity secret', message_type: :activity)

    expect(state[:messages]).to eq([{ speaker: 'customer', text: 'A refund please' }, { speaker: 'agent', text: 'I can help' }])
  end

  it 'only sends explicitly allowed customer attributes' do
    conversation.contact.update!(custom_attributes: { deployment: 'self_hosted', secret: 'contact secret' })
    conversation.update!(custom_attributes: { deployment: 'cloud', secret: 'conversation secret' })
    create(:message, conversation: conversation, account: account)

    with_modified_env(CONVERSATION_MONITORS_ATTRIBUTES: 'deployment') do
      expect(state[:customer_context]).to eq(contact_attributes: { 'deployment' => 'self_hosted' },
                                             conversation_attributes: { 'deployment' => 'cloud' })
      expect(state.to_json).not_to include('secret')
    end
  end

  it 'reads beyond the first page without dropping messages with the same timestamp' do
    timestamp = 1.hour.ago
    messages = Array.new(51) do |index|
      { account_id: account.id, conversation_id: conversation.id, inbox_id: conversation.inbox_id,
        content: "Message #{index}", message_type: 0, private: false, created_at: timestamp, updated_at: timestamp }
    end
    Message.insert_all!(messages) # rubocop:disable Rails/SkipsModelValidations -- Import-shaped fixture exercises tied timestamps across pages.

    expect(state[:messages].map { |entry| entry[:text] }).to eq(Array.new(51) { |index| "Message #{index}" })
  end

  it 'reports oversized context instead of silently classifying a truncated conversation' do
    create(:message, conversation: conversation, account: account, content: 'a' * 15_000)
    create(:message, conversation: conversation, account: account, content: 'b' * 15_000)

    expect { state }.to raise_error(CustomExceptions::MonitorEvaluationError, 'context_limit')
  end

  it 'reports conversations with no public text as unevaluated' do
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Private only', private: true)

    expect { state }.to raise_error(CustomExceptions::MonitorEvaluationError, 'no_text')
  end
end
