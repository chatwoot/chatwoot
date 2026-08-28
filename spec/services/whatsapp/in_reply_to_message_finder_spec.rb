require 'rails_helper'

RSpec.describe Whatsapp::InReplyToMessageFinder do
  subject(:result) { described_class.new(conversation: conversation, source_id: reply_source_id).perform }

  let(:conversation) { create(:conversation) }
  let(:message_token) { '3AADF8441347E8571C10F4E3BFD3E0A1' }
  let(:stored_source_id) { "wamid.#{Base64.strict_encode64("phone:#{message_token}")}" }
  let(:reply_source_id) { "wamid.#{Base64.strict_encode64("bsuid:#{message_token}")}" }

  it 'finds a message with the exact source ID' do
    exact_message = create(:message, conversation: conversation, source_id: reply_source_id)

    expect(result).to eq(exact_message)
  end

  it 'finds a differently scoped WAMID with the same message token' do
    stored_message = create(:message, conversation: conversation, source_id: stored_source_id)

    expect(result).to eq(stored_message)
  end

  it 'ignores duplicate messages representing the same external WAMID' do
    first_message = create(:message, conversation: conversation, source_id: stored_source_id)
    create(:message, conversation: conversation, source_id: stored_source_id)

    expect(result).to eq(first_message)
  end

  it 'returns nil when different WAMIDs contain the same message token' do
    create(:message, conversation: conversation, source_id: stored_source_id)
    create(:message, conversation: conversation, source_id: "wamid.#{Base64.strict_encode64("other:#{message_token}")}")

    expect(result).to be_nil
  end

  it 'returns nil for a malformed WAMID' do
    create(:message, conversation: conversation, source_id: stored_source_id)
    reply_source_id = 'wamid.not-base64'

    result = described_class.new(conversation: conversation, source_id: reply_source_id).perform

    expect(result).to be_nil
  end
end
