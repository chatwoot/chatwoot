require 'rails_helper'

RSpec.describe Captain::Tools::SearchPastRepliesService do
  subject(:tool) { described_class.new(account: account, user: agent, conversation: current_conversation) }

  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:current_conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:past_conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:reply) do
    create(:message, account: account, conversation: past_conversation, message_type: :outgoing, sender: agent,
                     content: 'Open Contacts and click Export.', created_at: 1.day.ago)
  end

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    create(:message, account: account, conversation: past_conversation, message_type: :incoming, content: 'How do I export contacts?',
                     created_at: 2.days.ago)
  end

  def stub_index(*messages)
    allow(described_class).to receive(:candidate_message_ids).and_return(messages.map(&:id))
  end

  it 'returns the agent reply, the customer message it answered and the conversation' do
    stub_index(reply)

    result = tool.execute(query: 'export contacts')

    expect(result).to include("Conversation ##{past_conversation.display_id}")
    expect(result).to include('Customer: How do I export contacts?')
    expect(result).to include('Agent reply: Open Contacts and click Export.')
  end

  it 'searches the index with filters set by the server, limited to the search window and the agent inboxes' do
    stub_index

    freeze_time do
      tool.execute(query: 'export contacts')

      expect(described_class).to have_received(:candidate_message_ids).with(
        'export contacts',
        where: { account_id: account.id, message_type: 'outgoing', private: false, sender_type: 'User',
                 conversation_id: { not: current_conversation.id },
                 created_at: { gte: Limits.search_time_range_limit_days.days.ago }, inbox_id: [inbox.id] }
      )
    end
  end

  it 'searches every inbox for an administrator' do
    admin = create(:user, account: account, role: :administrator)
    stub_index

    described_class.new(account: account, user: admin, conversation: current_conversation).execute(query: 'export contacts')

    expect(described_class).to have_received(:candidate_message_ids).with('export contacts', where: hash_excluding(:inbox_id))
  end

  it 'ignores scope arguments the model adds' do
    stub_index

    tool.execute(query: 'export contacts', account_id: create(:account).id, conversation_id: 1)

    expect(described_class).to have_received(:candidate_message_ids).with('export contacts', where: hash_including(account_id: account.id))
  end

  it 'drops a message from another account even if the index returns it' do
    other_account = create(:account)
    other_conversation = create(:conversation, account: other_account)
    other_reply = create(:message, account: other_account, conversation: other_conversation, message_type: :outgoing,
                                   content: 'Secret answer for another account.')
    stub_index(other_reply)

    expect(tool.execute(query: 'export contacts')).to eq('No past replies found for the given query')
  end

  it 'drops a conversation the agent cannot open' do
    hidden_inbox = create(:inbox, account: account)
    hidden_conversation = create(:conversation, account: account, inbox: hidden_inbox)
    hidden_reply = create(:message, account: account, conversation: hidden_conversation, message_type: :outgoing, sender: agent,
                                    content: 'Answer in an inbox the agent cannot see.')
    stub_index(hidden_reply)

    expect(tool.execute(query: 'export contacts')).to eq('No past replies found for the given query')
  end

  it 'drops private notes, bot replies and the current conversation' do
    note = create(:message, account: account, conversation: past_conversation, message_type: :outgoing, sender: agent, private: true,
                            content: 'Internal note.')
    bot_reply = create(:message, account: account, conversation: past_conversation, message_type: :outgoing,
                                 sender: create(:agent_bot, account: account), content: 'Bot answer.')
    current_reply = create(:message, account: account, conversation: current_conversation, message_type: :outgoing, sender: agent,
                                     content: 'Answer in this conversation.')
    stub_index(note, bot_reply, current_reply)

    expect(tool.execute(query: 'export contacts')).to eq('No past replies found for the given query')
  end

  it 'rejects malformed queries without searching' do
    stub_index(reply)

    expect(tool.execute(query: 'ab')).to include('between 3 and 200 characters')
    expect(tool.execute(query: { 'text' => 'export' })).to include('between 3 and 200 characters')
    expect(tool.execute).to include('between 3 and 200 characters')
    expect(described_class).not_to have_received(:candidate_message_ids)
  end

  it 'stops after the search limit for one draft' do
    stub_index(reply)

    described_class::MAX_SEARCHES.times { tool.execute(query: 'export contacts') }

    expect(tool.execute(query: 'export contacts')).to include('search limit')
    expect(described_class).to have_received(:candidate_message_ids).exactly(described_class::MAX_SEARCHES).times
  end

  it 'reports a search failure and lets the draft continue' do
    allow(described_class).to receive(:candidate_message_ids).and_raise(StandardError, 'index down')
    tracker = instance_double(ChatwootExceptionTracker, capture_exception: true)
    allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

    expect(tool.execute(query: 'export contacts')).to eq('Past replies are unavailable right now.')
    expect(tracker).to have_received(:capture_exception)
  end

  describe 'with the database source' do
    subject(:tool) { described_class.new(account: account, user: agent, conversation: current_conversation, source: :database) }

    it 'finds agent replies containing every search word, with the customer message they answered' do
      result = tool.execute(query: 'click export')

      expect(result).to include("Conversation ##{past_conversation.display_id}")
      expect(result).to include('Customer: How do I export contacts?')
      expect(result).to include('Agent reply: Open Contacts and click Export.')
    end

    it 'only returns replies the agent may read' do
      other_account = create(:account)
      create(:message, account: other_account, conversation: create(:conversation, account: other_account), message_type: :outgoing,
                       content: 'Other account: click export here.')
      hidden_conversation = create(:conversation, account: account, inbox: create(:inbox, account: account))
      create(:message, account: account, conversation: hidden_conversation, message_type: :outgoing, sender: agent,
                       content: 'Hidden inbox: click export here.')
      create(:message, account: account, conversation: past_conversation, message_type: :outgoing, sender: agent, private: true,
                       content: 'Private note: click export here.')
      create(:message, account: account, conversation: past_conversation, message_type: :outgoing,
                       sender: create(:agent_bot, account: account), content: 'Bot: click export here.')
      create(:message, account: account, conversation: current_conversation, message_type: :outgoing, sender: agent,
                       content: 'This conversation: click export here.')

      result = tool.execute(query: 'click export')

      expect(result).to include('Agent reply: Open Contacts and click Export.')
      expect(result).not_to include('Other account', 'Hidden inbox', 'Private note', 'Bot:', 'This conversation')
    end

    it 'finds the agent reply even when newer matches in inboxes they cannot open would fill every candidate place' do
      hidden_conversation = create(:conversation, account: account, inbox: create(:inbox, account: account))
      (described_class::CANDIDATE_LIMIT + 1).times do
        create(:message, account: account, conversation: hidden_conversation, message_type: :outgoing, sender: agent,
                         content: 'Hidden inbox: click export here.')
      end

      expect(tool.execute(query: 'click export')).to include('Agent reply: Open Contacts and click Export.')
    end

    it 'skips replies older than the search window' do
      reply.update!(created_at: (Limits.search_time_range_limit_days + 1).days.ago)

      expect(tool.execute(query: 'click export')).to eq('No past replies found for the given query')
    end

    it 'treats search syntax in the query as plain text' do
      expect(tool.execute(query: '%%% ___ export')).to include('Agent reply: Open Contacts and click Export.')
    end
  end
end
