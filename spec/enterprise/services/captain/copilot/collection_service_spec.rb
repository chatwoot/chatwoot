require 'rails_helper'

RSpec.describe Captain::Copilot::CollectionService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: admin) }
  let(:message) { create(:captain_copilot_message, account: account, copilot_thread: thread) }
  let(:turn) { CopilotRun::Turn.create!(account: account, user: admin, copilot_thread: thread, copilot_message: message) }
  let(:token) { turn.claim }
  let!(:conversations) do
    (1..10).map { |day| create(:conversation, account: account, inbox: inbox, created_at: Time.utc(2023, 9, day, 10)) }
  end

  def collect(call_id = 'data-1', **arguments)
    described_class.new(turn, tool_call: turn.tool_calls.create!(call_id: call_id, name: 'get_data'), token: token).create(**arguments)
  end

  it 'samples records spread across the period, and counts and dates every match' do
    result = collect(resource: 'conversations', filters: { 'date_field' => 'created_at', 'sample' => 3 })

    expect(CopilotRun::Collection.find(result[:collection_id]).selected_ids).to eq(conversations.values_at(9, 6, 3).map(&:id))
    expect(result).to include(total: 10, selected: 3, dates: include(first: '2023-09-01T10:00:00Z', last: '2023-09-10T10:00:00Z'))
  end

  it 'matches any of a list of values for a column' do
    conversations.first(2).each(&:resolved!)
    conversations.third.pending!

    expect(collect(resource: 'conversations', filters: { 'status' => %w[open pending] })[:total]).to eq(8)
  end

  it 'refuses newest and sample together' do
    expect { collect(resource: 'conversations', filters: { 'newest' => 5, 'sample' => 3 }) }.to raise_error(ArgumentError, /not both/)
  end

  it 'starts from every record of a set larger than the saved IDs, because the set is rebuilt as a query' do
    conversations.each { |conversation| create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming) }
    stub_const('CopilotRun::MAX_SELECTION', 3)
    all = collect(resource: 'conversations', filters: {})

    messages = collect('data-2', resource: 'messages', filters: {}, from: all[:collection_id])
    linked = collect('data-3', resource: 'conversations', filters: {}, from: messages[:collection_id])

    expect(all).to include(total: 10, selected: 3, selection_truncated: true)
    expect(messages[:total]).to eq(10)
    expect(linked[:total]).to eq(10)
  end

  it 'starts from the records a set under the limit saved, not the ones its filters match now' do
    conversations.each { |conversation| create(:message, conversation: conversation, account: account, inbox: inbox, message_type: :incoming) }
    open = collect(resource: 'conversations', filters: { 'status' => 'open' })
    conversations.first(3).each(&:resolved!)

    messages = collect('data-2', resource: 'messages', filters: {}, from: open[:collection_id])

    expect(open[:total]).to eq(10)
    expect(messages[:total]).to eq(10)
  end

  it 'keeps the conversations without labels' do
    conversations.first(2).each { |conversation| conversation.update!(label_list: ['billing']) }

    expect(collect(resource: 'conversations', filters: { 'empty' => ['labels'] })[:total]).to eq(8)
  end

  it 'starts from a set filtered by label' do
    conversations.first(2).each { |conversation| conversation.update!(label_list: ['billing']) }
    create(:message, conversation: conversations.first, account: account, inbox: inbox, message_type: :incoming)
    labelled = collect(resource: 'conversations', filters: { 'labels' => ['billing'] })

    messages = collect('data-2', resource: 'messages', filters: {}, from: labelled[:collection_id])

    expect(labelled[:total]).to eq(2)
    expect(messages[:total]).to eq(1)
  end

  it 'keeps only the records not linked to an excluded set, such as inboxes without members' do
    empty_inbox = create(:inbox, account: account)
    create(:inbox_member, user: admin, inbox: inbox)
    members = collect(resource: 'inbox_members', filters: {})

    result = collect('data-2', resource: 'inboxes', filters: {}, exclude_from: members[:collection_id])

    expect(CopilotRun::Collection.find(result[:collection_id]).selected_ids).to eq([empty_inbox.id])
  end

  it 'counts by period in the account time zone and names the zone' do
    account.update!(reporting_timezone: 'America/Los_Angeles')

    result = collect(resource: 'conversations', filters: { 'date_field' => 'created_at', 'since' => '2023-09-01T00:00:00Z',
                                                           'before' => '2023-09-04T00:00:00Z' }, group_by: 'day')

    expect(result[:time_zone]).to eq('America/Los_Angeles')
    expect(result[:aggregate][:groups].pluck(:group)).to eq(%w[2023-08-31 2023-09-01 2023-09-02 2023-09-03])
  end
end
