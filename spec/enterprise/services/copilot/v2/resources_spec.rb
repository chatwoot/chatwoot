require 'rails_helper'

RSpec.describe Copilot::V2::Resources do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, created_at: 2.months.ago) }
  let(:service) { described_class.new(account: account, user: user) }

  before { create(:inbox_member, user: user, inbox: inbox) }

  it 'selects only authorized account conversations and denies a nonmember Super Admin' do
    conversation
    create(:conversation, account: account)
    create(:conversation)
    expect(service.select(resource: 'conversations')['selected_ids']).to eq([conversation.id])
    outsider = create(:super_admin)
    expect { described_class.new(account: account, user: outsider).catalog }.to raise_error(Pundit::NotAuthorizedError)
  end

  it 'allows team-only access and combines custom role unassigned and participating grants' do
    team = create(:team, account: account)
    create(:team_member, user: user, team: team)
    team_conversation = create(:conversation, account: account, team: team, assignee: nil)
    participant_conversation = create(:conversation, account: account, inbox: inbox, assignee: create(:user, account: account))
    create(:conversation_participant, account: account, conversation: participant_conversation, user: user)
    role = create(:custom_role, account: account, permissions: %w[conversation_unassigned_manage conversation_participating_manage])
    account.account_users.find_by!(user: user).update!(role: :agent, custom_role: role)
    expect(service.select(resource: 'conversations')['selected_ids']).to contain_exactly(team_conversation.id, participant_conversation.id)
  end

  it 'deduplicates assigned OR mentioned while keeping mention dates and status independent' do
    conversation.update!(assignee: user, status: :open)
    create(:mention, account: account, conversation: conversation, user: user, mentioned_at: 10.days.ago)
    mentioned = create(:conversation, account: account, inbox: inbox, status: :open)
    create(:mention, account: account, conversation: mentioned, user: user)
    closed = create(:conversation, account: account, inbox: inbox, status: :resolved)
    create(:mention, account: account, conversation: closed, user: user)
    selection = service.select(resource: 'conversations', personal: 'assigned_or_mentioned',
                               mention_window: { 'since' => 1.day.ago.iso8601, 'until' => Time.current.iso8601(6) },
                               filters: [{ 'field' => 'status', 'operator' => 'eq', 'value' => 'open' }])
    expect(selection['selected_ids']).to contain_exactly(conversation.id, mentioned.id)
    expect(service.select(resource: 'conversations',
                          personal: 'mentioned_me')['selected_ids']).to contain_exactly(conversation.id, mentioned.id,
                                                                                        closed.id)
  end

  it 'validates field names, operators, types and custom definitions without accepting authority arguments' do
    conversation.update!(custom_attributes: { 'plan' => 'gold' })
    create(:custom_attribute_definition, account: account, attribute_model: :conversation_attribute, attribute_key: 'plan',
                                         attribute_display_type: :list, attribute_values: %w[gold silver])
    filter = { 'field' => 'custom_attributes.plan', 'operator' => 'eq', 'value' => 'gold' }
    expect(service.select(resource: 'conversations', filters: [filter])['selected_ids']).to eq([conversation.id])
    expect { service.select(resource: 'conversations', filters: [filter.merge('value' => 'wrong')]) }.to raise_error(ArgumentError)
    expect { service.select(resource: 'conversations', fields: ['account_id']) }.to raise_error(ArgumentError)
    expect do
      service.select(resource: 'conversations', filters: [{ 'field' => 'id', 'operator' => 'eq', 'value' => '1 OR 1' }])
    end.to raise_error(ArgumentError)
    expect { service.select(resource: 'conversations', account_id: account.id) }.to raise_error(ArgumentError)
  end

  it 'distinguishes user limits from server caps and uses stable ordering' do
    conversation
    another = create(:conversation, account: account, inbox: inbox, created_at: conversation.created_at)
    stub_const('Copilot::V2::Resources::MAX_SELECTED', 1)
    all = service.select(resource: 'conversations')
    expect(all['selected_ids']).to eq([conversation.id])
    expect(all['selection']).to include('complete' => false, 'cap_reached' => true, 'matching_count' => 2)
    limited = service.select(resource: 'conversations', limit: 1, order: 'newest')
    expect(limited['selected_ids']).to eq([another.id])
    expect(limited['selection']).to include('complete' => true, 'cap_reached' => false)
  end

  it 'captures all in-window messages from old conversations, including private replies and excluding activities and templates' do
    create(:message, account: account, conversation: conversation, created_at: 8.days.ago)
    incoming = create(:message, account: account, conversation: conversation, sender: conversation.contact, message_type: :incoming)
    reply = create(:message, account: account, conversation: conversation, sender: user, message_type: :outgoing)
    note = create(:message, account: account, conversation: conversation, sender: user, message_type: :outgoing, private: true)
    create(:message, account: account, conversation: conversation, message_type: :activity)
    create(:message, account: account, conversation: conversation, message_type: :template)
    stub_const('Copilot::V2::Resources::PAGE_SIZE', 1)
    selection = service.select(resource: 'conversations')
    evidence = service.read_related(selection, relationship: 'messages')
    expect(evidence['items'].first['records'].pluck('id')).to contain_exactly(incoming.id, reply.id, note.id)
    expect(Time.iso8601(evidence['window']['until']) - Time.iso8601(evidence['window']['since'])).to eq(7.days)
    expect(evidence['message_watermarks'][conversation.id.to_s]).to eq(conversation.messages.maximum(:id))
    customers = service.read_related(selection, relationship: 'messages', customer_only: true)
    expect(customers['items'].first['records'].pluck('id')).to eq([incoming.id])
    expect { described_class.require_message_evidence!(selection) }.to raise_error(ArgumentError, /Message evidence/)
    expect { described_class.require_message_evidence!(evidence) }.not_to raise_error
    expect(JSON.parse(JSON.generate(evidence))).to eq(evidence)
  end

  it 'marks oversized evidence unresolved without retaining a truncated subset and continues other conversations' do
    create(:message, account: account, conversation: conversation, content: 'a' * 2_000)
    other = create(:conversation, account: account, inbox: inbox)
    create(:message, account: account, conversation: other, content: 'small')
    stub_const('Copilot::V2::Resources::MAX_EVIDENCE_BYTES', 1_000)
    evidence = service.read_related(service.select(resource: 'conversations'), relationship: 'messages')
    expect(evidence['complete']).to be(false)
    expect(evidence['unresolved_ids']).to eq([conversation.id])
    expect(evidence['resolved_ids']).to eq([other.id])
    expect(evidence['items'].first).to include('reason' => 'evidence_too_large', 'records' => [])
  end

  it 'rechecks selected parents and reports lost access without silently dropping identities' do
    selection = service.select(resource: 'conversations', filters: [{ 'field' => 'id', 'operator' => 'eq', 'value' => conversation.id }])
    inbox.inbox_members.destroy_all
    evidence = service.read_related(selection, relationship: 'messages')
    expect(evidence['unresolved_ids']).to eq([conversation.id])
    expect(evidence['items'].first['reason']).to eq('record_unavailable')
    expect { service.authorize_manifest!(selection) }.to raise_error(Pundit::NotAuthorizedError)
  end

  it 'independently authorizes contact relationships, notes and custom role contact access' do
    contact = conversation.contact
    hidden = create(:conversation, account: account, contact: contact)
    note = create(:note, account: account, contact: contact)
    selection = service.select(resource: 'contacts', filters: [{ 'field' => 'id', 'operator' => 'eq', 'value' => contact.id }])
    evidence = service.read_related(selection, relationship: 'conversations')
    expect(evidence['items'].first['records'].pluck('id')).to eq([conversation.id])
    expect(evidence['items'].first['records'].pluck('id')).not_to include(hidden.id)
    expect(service.read_related(selection, relationship: 'notes')['items'].first['records'].pluck('id')).to eq([note.id])
    role = create(:custom_role, account: account, permissions: ['conversation_manage'])
    account.account_users.find_by!(user: user).update!(custom_role: role)
    expect { service.read_related(selection, relationship: 'notes') }.to raise_error(Pundit::NotAuthorizedError)
    expect(service.catalog).not_to have_key('contacts')
  end

  it 'counts only new authorized messages after the capture watermark with the same speaker filters' do
    create(:message, account: account, conversation: conversation, sender: conversation.contact, message_type: :incoming)
    evidence = service.read_related(service.select(resource: 'conversations'), relationship: 'messages', customer_only: true)
    create(:message, account: account, conversation: conversation, sender: user, message_type: :outgoing)
    create(:message, account: account, conversation: conversation, sender: conversation.contact, message_type: :incoming)
    result = service.freshness(evidence)
    expect(result).to include('conversation_count' => 1, 'message_count' => 1)
  end

  it 'keeps unattended independent from assigned-or-mentioned and supports full-history evidence explicitly' do
    conversation.update!(assignee: user, waiting_since: 3.days.ago)
    old_message = create(:message, account: account, conversation: conversation, created_at: 30.days.ago)
    selection = service.select(resource: 'conversations', personal: 'assigned_or_mentioned', fields: ['id'], order: 'oldest_waiting',
                               filters: [{ 'field' => 'unattended', 'operator' => 'eq', 'value' => true }])
    expect(selection['selected_ids']).to eq([conversation.id])
    evidence = service.read_related(selection, relationship: 'messages',
                                               window: { 'since' => Time.at(0).utc.iso8601, 'until' => Time.current.iso8601(6) })
    expect(evidence['items'].first['records'].pluck('id')).to eq([old_message.id])
    expect(evidence['items'].first['identity']).to include('display_id' => conversation.display_id, 'contact_id' => conversation.contact_id)
    expect(service.catalog.dig('conversations', 'filters', 'status', 'values')).to include('open')
    account.update!(status: :suspended)
    expect { service.catalog }.to raise_error(Pundit::NotAuthorizedError)
  end

  it 'authorizes captured partial items separately and preserves stored text after a message deletion' do
    message = create(:message, account: account, conversation: conversation)
    other = create(:conversation, account: account, inbox: inbox)
    selection = service.select(resource: 'conversations')
    other.destroy!
    evidence = service.read_related(selection, relationship: 'messages')
    expect(evidence['unresolved_ids']).to eq([other.id])
    message.destroy!
    expect(service.authorize_manifest!(evidence, item_ids: [conversation.id])).to be(true)
    expect(evidence['items'].first['records'].pluck('id')).to eq([message.id])
    expect { service.authorize_manifest!(evidence, item_ids: [other.id]) }.to raise_error(ArgumentError)
  end
end
