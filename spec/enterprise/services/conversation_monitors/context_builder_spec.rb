require 'rails_helper'

RSpec.describe ConversationMonitors::ContextBuilder do
  subject(:state) { described_class.new(conversation).build }

  let(:conversation) { create(:conversation) }
  let(:account) { conversation.account }

  it 'preserves HTML block and line-break boundaries without splitting inline words' do
    create(:message, conversation: conversation, account: account,
                     content: '<p>re<strong>fund</strong></p><div>denied<br>please &amp; thanks</div><ul><li>first</li><li>second</li></ul>')

    expect(state[:messages].sole[:text].split).to include('refund', 'denied', 'please', '&', 'thanks', 'first', 'second')
    expect(state[:messages].sole[:text]).not_to include('refunddenied', 'deniedplease', '<strong>')
  end

  it 'includes public evidence and excludes private notes, activity and deleted messages' do
    create(:message, conversation: conversation, account: account, content: '<p>A refund please</p>')
    create(:message, :outgoing, conversation: conversation, account: account, content: 'I can help')
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Private secret', private: true)
    create(:message, conversation: conversation, account: account, content: 'Old secret', content_attributes: { deleted: true })
    create(:message, conversation: conversation, account: account, content: 'Activity secret', message_type: :activity)

    expect(state[:messages]).to eq([{ speaker: 'customer', text: 'A refund please' }, { speaker: 'agent', text: 'I can help' }])
    expect(described_class.new(conversation, message_limit: 5).build).to eq(state)
  end

  it 'uses the newest five public text messages in order without counting private, deleted, or empty entries' do
    timestamp = 1.hour.ago
    7.times do |index|
      create(:message, conversation: conversation, account: account, message_type: index.even? ? :incoming : :outgoing,
                       content: "Public #{index}", created_at: timestamp)
    end
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Private note', private: true)
    create(:message, conversation: conversation, account: account, content: 'Deleted text', content_attributes: { deleted: true })
    create(:message, conversation: conversation, account: account, content: 'Activity', message_type: :activity)
    create(:message, conversation: conversation, account: account, content: '[Attachment]')

    limited = described_class.new(conversation, message_limit: 5).build

    expect(limited[:messages].pluck(:text)).to eq(['Public 2', 'Public 3', 'Public 4', 'Public 5', 'Public 6'])
    expect(limited[:messages].pluck(:speaker)).to eq(%w[customer agent customer agent customer])
    expect(limited[:truncated]).to be(true)
    expect(state[:messages].size).to eq(7)
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

  it 'keeps recent messages and trims the oldest retained text to fit the serialized context limit' do
    create(:message, conversation: conversation, account: account, content: 'a' * 15_000)
    create(:message, :outgoing, conversation: conversation, account: account, content: 'b' * 15_000)

    expect(state[:truncated]).to be(true)
    expect(state.to_json.bytesize).to be <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES
    expect(state[:messages].last).to eq(speaker: 'agent', text: 'b' * 15_000)
    expect(state[:messages].first[:speaker]).to eq('customer')
    expect(state[:messages].first[:text].length).to be_between(1, 14_999)
    expect(state[:messages].first[:text]).to eq('a' * state[:messages].first[:text].length)
    expect(described_class.new(conversation, message_limit: 5).build).to eq(state)
  end

  it 'trims a single oversized message on character boundaries and accounts for escaped JSON bytes' do
    text = "💬\"\\\n" * 6000
    create(:message, conversation: conversation, account: account, content: text)

    trimmed = state[:messages].sole[:text]
    expect(state[:truncated]).to be(true)
    expect(trimmed).not_to be_empty
    expect(trimmed.valid_encoding?).to be(true)
    expect(text).to end_with(trimmed)
    expect(state.to_json.bytesize).to be <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES
    expect(JSON.parse(state.to_json)['messages'].sole['text']).to eq(trimmed)
  end

  it 'keeps context unchanged at the exact serialized byte limit, including message separators' do
    create(:message, conversation: conversation, account: account, content: 'Older message')
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Latest reply')
    full_state = state
    stub_const('ConversationMonitors::Configuration::MAX_CONTEXT_BYTES', full_state.to_json.bytesize)

    expect(described_class.new(conversation).build).to eq(full_state)
    expect(full_state[:truncated]).to be(false)

    stub_const('ConversationMonitors::Configuration::MAX_CONTEXT_BYTES', full_state.to_json.bytesize - 2)
    trimmed = described_class.new(conversation).build
    expect(trimmed[:truncated]).to be(true)
    expect(trimmed.to_json.bytesize).to be <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES
    expect(trimmed[:messages].last[:text]).to eq('Latest reply')

    latest_only = full_state.merge(messages: [full_state[:messages].last])
    stub_const('ConversationMonitors::Configuration::MAX_CONTEXT_BYTES', latest_only.to_json.bytesize)
    expect(described_class.new(conversation).build).to eq(latest_only.merge(truncated: true))
  end

  it 'omits oversized attribute values while preserving smaller allowed facts and room for messages' do
    conversation.contact.update!(custom_attributes: { oversized: 'x' * 30_000, deployment: 'self_hosted', secret: 'Hidden' })
    create(:message, conversation: conversation, account: account, content: 'Need help with automations')

    with_modified_env(CONVERSATION_MONITORS_ATTRIBUTES: 'oversized,deployment') do
      expect(state[:truncated]).to be(true)
      expect(state[:customer_context]).to eq(contact_attributes: { 'deployment' => 'self_hosted' }, conversation_attributes: {})
      expect(state[:messages].sole[:text]).to eq('Need help with automations')
      expect(state.to_json.bytesize).to be <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES
    end
  end

  it 'reports conversations with no public text as unevaluated' do
    create(:message, :outgoing, conversation: conversation, account: account, content: 'Private only', private: true)

    expect { state }.to raise_error(CustomExceptions::MonitorEvaluationError, 'no_text')
  end
end
