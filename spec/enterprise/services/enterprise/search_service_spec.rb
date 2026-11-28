require 'rails_helper'

RSpec.describe Enterprise::SearchService do
  subject(:search) do
    SearchService.new(current_user: user, current_account: account, params: { q: 'restricted search term' }, search_type: 'Message')
  end

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account, enable_auto_assignment: false) }
  let(:assigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }
  let(:restricted_conversation) do
    create(:conversation, account: account, inbox: inbox, assignee: create(:user, account: account))
  end
  let!(:assigned_message) do
    create(:message, account: account, inbox: inbox, conversation: assigned_conversation, content: 'restricted search term')
  end
  let!(:restricted_message) do
    create(:message, account: account, inbox: inbox, conversation: restricted_conversation, content: 'restricted search term')
  end

  before do
    Current.account = account
    create(:inbox_member, user: user, inbox: inbox)
    custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
    account.account_users.find_by!(user: user).update!(role: :agent, custom_role: custom_role)
  end

  after { Current.account = nil }

  it 'returns messages only from conversations the agent can access' do
    message_ids = search.perform[:messages].map(&:id)

    expect(message_ids).to contain_exactly(assigned_message.id)
    expect(message_ids).not_to include(restricted_message.id)
  end

  it 'applies the same permission scope to conversation search' do
    assigned_conversation.contact.update!(name: 'restricted search term')
    restricted_conversation.contact.update!(name: 'restricted search term')
    conversation_search = SearchService.new(
      current_user: user,
      current_account: account,
      params: { q: 'restricted search term' },
      search_type: 'Conversation'
    )

    expect(conversation_search.perform[:conversations].map(&:id)).to contain_exactly(assigned_conversation.id)
  end

  it 'uses permission-aware SQL search instead of the search index' do
    allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
    allow(account).to receive(:feature_enabled?).and_call_original
    allow(account).to receive(:feature_enabled?).with('advanced_search').and_return(true)

    expect(search.send(:should_run_advanced_search?)).to be false
    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
  end

  it 'uses the conversation subject only when the message subject is blank' do
    assigned_message.update!(content: 'no content match', content_attributes: { email: { subject: 'restricted search term' } })
    restricted_message.update!(content: 'no content match', content_attributes: { email: { subject: 'restricted search term' } })
    assigned_conversation.update!(additional_attributes: { mail_subject: 'restricted search term' })
    fallback_message = create(:message, account: account, inbox: inbox, conversation: assigned_conversation, content: 'no content match')
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: assigned_conversation,
      content: 'no content match',
      content_attributes: { email: { subject: 'different subject' } }
    )
    account.enable_features!('advanced_search')

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id, fallback_message.id)
  end

  it 'preserves transcription search for accessible conversations' do
    assigned_message.update!(content: 'no content match')
    restricted_message.update!(content: 'no content match')
    assigned_message.attachments.create!(
      account: account, file_type: :audio, meta: { transcribed_text: 'restricted search term' }
    )
    restricted_message.attachments.create!(
      account: account, file_type: :audio, meta: { transcribed_text: 'restricted search term' }
    )
    account.enable_features!('advanced_search')

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
  end

  it 'searches call transcripts for accessible conversations' do
    account.enable_features!('advanced_search')
    [assigned_message, restricted_message].each do |message|
      message.update!(content: 'no content match', content_type: :voice_call)
      create(:call, conversation: message.conversation, message: message, transcript: 'restricted search term')
    end

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
  end

  it 'does not use the subject of an inaccessible conversation' do
    account.enable_features!('advanced_search')
    assigned_message.update!(content: 'no content match')
    restricted_message.update!(content: 'no content match')
    assigned_conversation.update!(additional_attributes: { mail_subject: 'restricted search term' })
    restricted_conversation.update!(additional_attributes: { mail_subject: 'restricted search term' })

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
  end

  context 'when the agent is not a member of every inbox' do
    before { create(:inbox, account: account) }

    it 'returns messages only from conversations the agent can access' do
      expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
    end

    it 'returns conversations only the agent can access' do
      assigned_conversation.contact.update!(name: 'restricted search term')
      restricted_conversation.contact.update!(name: 'restricted search term')
      conversation_search = SearchService.new(
        current_user: user, current_account: account, params: { q: 'restricted search term' }, search_type: 'Conversation'
      )

      expect(conversation_search.perform[:conversations].map(&:id)).to contain_exactly(assigned_conversation.id)
    end
  end

  it 'includes conversations the agent participates in' do
    create(:conversation_participant, conversation: restricted_conversation, user: user, account: account)

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id, restricted_message.id)
  end

  it 'applies the permission scope to the combined search' do
    assigned_conversation.contact.update!(name: 'restricted search term')
    restricted_conversation.contact.update!(name: 'restricted search term')
    combined_search = SearchService.new(
      current_user: user, current_account: account, params: { q: 'restricted search term' }, search_type: 'all'
    )
    result = combined_search.perform

    expect(result[:messages].map(&:id)).to contain_exactly(assigned_message.id)
    expect(result[:conversations].map(&:id)).to contain_exactly(assigned_conversation.id)
  end

  it 'limits an unassigned role to unassigned and own conversations' do
    account.account_users.find_by!(user: user).custom_role.update!(permissions: ['conversation_unassigned_manage'])
    unassigned_conversation = create(:conversation, account: account, inbox: inbox, assignee: nil)
    unassigned_message = create(
      :message, account: account, inbox: inbox, conversation: unassigned_conversation, content: 'restricted search term'
    )

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id, unassigned_message.id)
  end

  it 'returns no conversation content when the role has no conversation permission' do
    account.account_users.find_by!(user: user).custom_role.update!(permissions: ['knowledge_base_manage'])
    assigned_conversation.contact.update!(name: 'restricted search term')
    combined_search = SearchService.new(
      current_user: user, current_account: account, params: { q: 'restricted search term' }, search_type: 'all'
    )
    result = combined_search.perform

    expect(result[:messages]).to be_empty
    expect(result[:conversations]).to be_empty
  end

  it 'keeps inbox-wide results for a role with full conversation access' do
    account.account_users.find_by!(user: user).custom_role.update!(permissions: ['conversation_manage'])

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id, restricted_message.id)
  end

  it 'applies the permission scope to GIN search' do
    account.enable_features!('search_with_gin')

    expect(search.perform[:messages].map(&:id)).to contain_exactly(assigned_message.id)
  end
end
