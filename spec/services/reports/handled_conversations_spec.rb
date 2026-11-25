require 'rails_helper'

# Handled conversations are read through the builders that serve them, since the
# metric only means something as the reports compute it.
RSpec.describe Reports::HandledConversations do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:other_inbox) { create(:inbox, account: account) }
  let(:team) { create(:team, account: account) }
  let(:ana) { create(:user, account: account, role: :agent) }
  let(:bruno) { create(:user, account: account, role: :agent) }
  # Holds conversations and never replies to any of them.
  let(:diego) { create(:user, account: account, role: :agent) }
  # In UTC, like the series it is read through. Built from Time.zone, it shifts by
  # whatever zone an earlier spec left behind and the series grows a leading day.
  let(:day) { Time.utc(2026, 9, 5, 12) }
  let(:since) { day.beginning_of_day }
  let(:until_time) { (day + 1.day).end_of_day }

  let(:shared) { create(:conversation, account: account, inbox: inbox, assignee: diego, team: team, created_at: day - 1.month) }
  let(:ana_only) { create(:conversation, account: account, inbox: other_inbox, assignee: diego, created_at: day) }

  def reply(conversation, sender, at, **attrs)
    create(:message, account: account, inbox: conversation.inbox, conversation: conversation,
                     message_type: :outgoing, sender: sender, created_at: at, **attrs)
  end

  before do
    travel_to day + 2.days
    reply(shared, ana, day)
    reply(shared, ana, day + 1.hour) # a second reply is still one conversation
    reply(shared, bruno, day + 1.day)
    reply(ana_only, ana, day + 2.hours)
    reply(ana_only, diego, day, private: true)
    campaign_only = create(:conversation, account: account, inbox: inbox, created_at: day)
    reply(campaign_only, bruno, day, additional_attributes: { campaign_id: 1 }) # a live chat campaign posting as Bruno
    reaction_only = create(:conversation, account: account, inbox: inbox, created_at: day)
    reply(reaction_only, bruno, day, content: '👍', content_attributes: { is_reaction: true, in_reply_to: 1 })
    automation_only = create(:conversation, account: account, inbox: inbox, created_at: day)
    reply(automation_only, bruno, day, content_attributes: { automation_rule_id: 1 })
    # Answered from the WhatsApp Business app: a human reply with no agent behind it.
    echoed = create(:conversation, account: account, inbox: other_inbox, team: team, created_at: day)
    create(:message, :bot_message, account: account, inbox: other_inbox, conversation: echoed,
                                   content_attributes: { external_echo: true }, created_at: day)
    bot_only = create(:conversation, account: account, inbox: other_inbox, created_at: day)
    create(:message, :bot_message, account: account, inbox: other_inbox, conversation: bot_only, created_at: day)
    create(:message, account: account, inbox: inbox, conversation: shared, message_type: :incoming, created_at: day)
    reply(create(:conversation, account: account, inbox: inbox, assignee: diego), bruno, day - 1.week) # out of range
  end

  def summary(builder, extra = {})
    builder.new(account: account, params: { since: since.to_i.to_s, until: until_time.to_i.to_s }.merge(extra)).build
  end

  def handled_by(rows)
    rows.to_h { |row| [row[:id], row[:handled_conversations_count]] }
  end

  describe 'agent summary' do
    it 'credits each conversation to everyone who sent it a public message, once' do
      expect(handled_by(summary(V2::Reports::AgentSummaryBuilder))).to include(ana.id => 2, bruno.id => 1, diego.id => 0)
    end

    it 'does not take the assignment for handling' do
      row = summary(V2::Reports::AgentSummaryBuilder).find { |r| r[:id] == diego.id }

      expect(row).to include(conversations_count: 1, handled_conversations_count: 0)
    end

    it 'counts only the inbox the report is narrowed to' do
      expect(handled_by(summary(V2::Reports::AgentSummaryBuilder, inbox_id: inbox.id))).to eq(ana.id => 1, bruno.id => 1)
    end
  end

  it 'counts distinct conversations per inbox and per team' do
    expect(handled_by(summary(V2::Reports::InboxSummaryBuilder))).to include(inbox.id => 1, other_inbox.id => 2)
    expect(handled_by(summary(V2::Reports::TeamSummaryBuilder))).to eq(team.id => 2)
  end

  describe 'timeseries' do
    let(:params) do
      { metric: described_class::METRIC, type: :account, since: since.to_i.to_s, until: until_time.to_i.to_s, group_by: 'day' }
    end

    it 'counts a conversation on every day it was handled' do
      values = V2::Reports::Conversations::ReportBuilder.new(account, params).timeseries.pluck(:value)

      expect(values).to eq([3, 1])
    end

    it 'counts it once over the whole period' do
      expect(V2::Reports::Conversations::ReportBuilder.new(account, params).aggregate_value).to eq(3)
    end

    it 'reads a single agent by what they sent' do
      agent_params = params.merge(type: :agent, id: bruno.id)

      expect(V2::Reports::Conversations::ReportBuilder.new(account, agent_params).timeseries.pluck(:value)).to eq([0, 1])
    end

    it 'is part of the metric cards' do
      summary = V2::Reports::Conversations::MetricBuilder.new(account, params.merge(type: :agent, id: ana.id)).summary

      expect(summary[:handled_conversations_count]).to eq(2)
    end
  end

  describe 'drilldown' do
    def drilldown(agent)
      params = { metric: described_class::METRIC, type: :agent, id: agent.id, since: since.to_i.to_s, until: until_time.to_i.to_s,
                 bucket_timestamp: since.to_i.to_s, group_by: 'day', timezone_offset: '0' }
      V2::Reports::DrilldownBuilder.new(account, params).build
    end

    it 'lists the conversations handled in the clicked bucket' do
      result = drilldown(ana)

      expect(result[:payload].map { |record| record[:conversation][:id] }).to contain_exactly(shared.id, ana_only.id)
      expect(result[:meta]).to include(record_type: 'conversation', conversation_count: 2)
    end

    it 'leaves out a conversation the agent only left a private note on' do
      expect(drilldown(diego)[:payload]).to be_empty
    end
  end

  # The partial index is what keeps a month of a busy account inside the statement
  # timeout, and it only serves queries whose WHERE implies its predicate. Sequential
  # and bitmap scans are switched off and every other index of `messages` is dropped
  # for the duration of the EXPLAIN, so the planner has no other way out: if the query
  # and the index predicate drift apart, the plan falls back to a disabled sequential
  # scan, and if the index stops covering the columns read, to a plain index scan.
  #
  # Leaving the other indexes in place made the result depend on the table statistics
  # (#813): once autovacuum has visited an empty `messages`, the planner expects one row,
  # and `index_messages_on_conversation_id` won on cost for the DISTINCT shapes, so the
  # spec failed or passed depending on which CI shard it landed in.
  describe 'query plan' do
    # The state CI hits: autovacuum visits `messages` while it holds only this example's rows,
    # which are not committed, so the statistics say the table is empty. Reproduced here on
    # purpose, through a connection of its own because VACUUM cannot run inside the example's
    # transaction, so the spec measures the plan in that state on every run instead of whenever
    # autovacuum happens to get there first.
    before do
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      connection = PG.connect(host: config[:host], port: config[:port], dbname: config[:database],
                              user: config[:username], password: config[:password])
      connection.exec('VACUUM messages')
    ensure
      connection&.close
    end

    def plan_for(relation)
      plan = nil
      ActiveRecord::Base.transaction(requires_new: true) do
        connection = ActiveRecord::Base.connection
        connection.execute('SET LOCAL enable_seqscan = off')
        connection.execute('SET LOCAL enable_bitmapscan = off')
        connection.select_values(<<~SQL.squish).each { |index| connection.execute("DROP INDEX #{index}") }
          SELECT indexrelid::regclass::text FROM pg_index
          WHERE indrelid = 'messages'::regclass AND NOT indisprimary
            AND indexrelid <> 'index_messages_on_handled_conversations'::regclass
        SQL
        plan = connection.select_values("EXPLAIN #{relation.to_sql}").join("\n")
        raise ActiveRecord::Rollback
      end
      plan
    end

    it 'answers every shape the reports read from the partial index alone' do
      range = since..until_time
      shapes = [
        described_class.messages(account.messages.where(created_at: range)).group('messages.sender_id').select('messages.sender_id'),
        described_class.distinct_conversations(account.messages.where(created_at: range)),
        described_class.distinct_conversations(ana.messages.where(account_id: account.id, created_at: range)),
        described_class.distinct_conversations(inbox.messages.where(account_id: account.id, created_at: range)),
        described_class.messages(account.messages.where(created_at: range)).joins(:conversation).group('conversations.team_id')
                       .select('conversations.team_id')
      ]

      shapes.each do |relation|
        expect(plan_for(relation)).to include('Index Only Scan using index_messages_on_handled_conversations')
      end
    end
  end
end
