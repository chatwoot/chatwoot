require 'rails_helper'

describe ConversationSnapshot do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'john doe') }
  let(:conversation) do
    create(:conversation, account: account, assignee: agent, custom_attributes: { 'fechamento' => 'Em negociação' })
  end

  it 'keeps the values the conversation had when it was captured' do
    snapshot = described_class.new(conversation)
    conversation.update!(assignee: nil, custom_attributes: {}, status: :resolved)

    expect(snapshot.assignee).to eq agent
    expect(snapshot.custom_attributes).to eq('fechamento' => 'Em negociação')
    expect(snapshot.status).to eq 'open'
  end

  it 'does not share the custom attributes hash with the conversation' do
    snapshot = described_class.new(conversation)
    conversation.custom_attributes['fechamento'] = 'Venda efetivada'

    expect(snapshot.custom_attributes['fechamento']).to eq 'Em negociação'
  end

  it 'recognises only the conversation it was taken from' do
    snapshot = described_class.new(conversation)

    expect(snapshot).to be_snapshot_of(conversation)
    expect(snapshot).not_to be_snapshot_of(create(:conversation, account: account))
    expect(snapshot).not_to be_snapshot_of(snapshot)
  end

  it 'exposes the identity of the conversation' do
    snapshot = described_class.new(conversation)

    expect(snapshot.id).to eq conversation.id
    expect(snapshot.display_id).to eq conversation.display_id
    expect(snapshot.contact).to eq conversation.contact
    expect(snapshot.account).to eq account
    expect(snapshot.inbox).to eq conversation.inbox
  end

  it 'leaves out the messages created after the capture' do
    older = create(:message, account: account, conversation: conversation, content: 'before the capture')
    snapshot = described_class.new(conversation)
    create(:message, account: account, conversation: conversation, content: 'after the capture')

    expect(snapshot.recent_messages.map(&:content)).to eq [older.content]
  end
end
