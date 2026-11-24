require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetReportService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(assistant, user: admin).tap { |tool| tool.tool_call = instance_double(CopilotToolCall, id: 7) } }
  let(:week) { { since: '2026-09-07', until: '2026-09-13' } }

  describe '#active?' do
    it 'is offered to administrators' do
      expect(service.active?).to be true
    end

    it 'is not offered to agents without report access' do
      expect(described_class.new(assistant, user: agent).active?).to be false
    end

    it 'is offered to a custom role with report_manage' do
      account.account_users.find_by(user: agent).update!(custom_role: create(:custom_role, account: account, permissions: ['report_manage']))

      expect(described_class.new(assistant, user: agent).active?).to be true
    end
  end

  describe '#execute' do
    before do
      create(:conversation, account: account, inbox: inbox, assignee: agent, created_at: Time.zone.parse('2026-09-08 10:00'))
      create_list(:conversation, 2, account: account, inbox: inbox, assignee: agent, created_at: Time.zone.parse('2026-09-09 10:00'))
    end

    it 'returns each metric per period for an agent, and a chart only when asked' do
      result = service.execute(by: 'day', metrics: %w[conversations_count], agent_id: agent.id, **week)

      series = result[:metrics].first
      expect(series[:points].first(3)).to eq([{ period: '2026-09-07', value: 0 }, { period: '2026-09-08', value: 1 },
                                              { period: '2026-09-09', value: 2 }])
      expect(series[:total_or_average]).to eq(3)
      expect(result).not_to include(:chart)

      charted = service.execute(by: 'day', metrics: %w[conversations_count], agent_id: agent.id, chart: true, **week)
      expect(charted[:chart]).to eq('[copilot-chart:7]')
      expect(charted[:chart_data].first).to include(title: "Conversations for #{agent.name} by day, 7 to 13 Sep 2026")
      expect(charted[:chart_data].first[:series].first[:data].first(3)).to eq([0, 1, 2])
    end

    it 'counts each day in the account time zone, not in another zone that shares its offset today' do
      create(:conversation, account: account, inbox: inbox, created_at: Time.utc(2026, 9, 10, 23, 30))

      points = service.execute(by: 'day', metrics: %w[conversations_count], **week)[:metrics].first[:points]

      expect(points[3]).to eq(period: '2026-09-10', value: 1)
      expect(points[4]).to eq(period: '2026-09-11', value: 0)
    end

    it 'starts each day at midnight in the reporting time zone, with that date\'s own offset' do
      account.update!(reporting_timezone: 'America/New_York')
      [Time.utc(2026, 10, 25, 2), Time.utc(2026, 11, 1, 3, 30), Time.utc(2026, 11, 8, 4, 30)].each do |created_at|
        create(:conversation, account: account, inbox: inbox, created_at: created_at)
      end

      series = service.execute(by: 'day', metrics: %w[conversations_count], since: '2026-10-25', until: '2026-11-07')[:metrics].first

      expect(series[:points].first).to eq(period: '2026-10-25', value: 0)
      expect(series[:points]).to include({ period: '2026-10-31', value: 1 })
      expect(series[:points].last).to eq(period: '2026-11-07', value: 1)
      expect(series[:total_or_average]).to eq(2)
    end

    it 'totals each metric over exactly the dates given, including the last day' do
      result = service.execute(by: 'range', metrics: %w[conversations_count], since: '2026-09-08', until: '2026-09-08')

      expect(result).to include(since: '2026-09-08', until: '2026-09-08')
      expect(result[:metrics]).to eq([{ metric: 'conversations_count', total_or_average: 1, data_from: '2026-09-08', data_to: '2026-09-08' }])
    end

    it 'reports the last N days as the reports pages count them, today included, and not together with dates' do
      travel_to Time.zone.parse('2026-09-10 12:00') do
        result = service.execute(by: 'range', metrics: %w[conversations_count], last_days: 3)

        expect(result).to include(since: '2026-09-08', until: '2026-09-10')
        expect(result[:metrics].first[:total_or_average]).to eq(3)
        expect { service.execute(by: 'range', metrics: %w[conversations_count], last_days: 3, **week) }
          .to raise_error(ArgumentError, /not both/)
      end
    end

    it 'gives an average time in its two largest units' do
      create(:reporting_event, account: account, inbox: inbox, name: 'first_response', value: 178_813,
                               created_at: Time.zone.parse('2026-09-08 10:00'))

      result = service.execute(by: 'range', metrics: %w[avg_first_response_time], **week)

      expect(result[:metrics].first[:total_or_average]).to eq('2 days and 1 hour')
    end

    it 'gives a measured zero average as zero time, and no time for a period without events' do
      create(:reporting_event, account: account, inbox: inbox, name: 'first_response', value: 600, value_in_business_hours: 0,
                               created_at: Time.zone.parse('2026-09-08 10:00'))

      series = service.execute(by: 'day', metrics: %w[avg_first_response_time], business_hours: true, **week)[:metrics].first

      expect(series).to include(total_or_average: '0 seconds', data_from: '2026-09-08', data_to: '2026-09-08')
      expect(series[:points].first(2)).to eq([{ period: '2026-09-07', value: 0, duration: nil, events: 0 },
                                              { period: '2026-09-08', value: 0, duration: '0 seconds', events: 1 }])
    end

    it 'counts a conversation with bot handoffs on two days once in the total, as the reports pages do' do
      conversation = create(:conversation, account: account, inbox: inbox, created_at: Time.zone.parse('2026-09-08 09:00'))
      %w[2026-09-08 2026-09-10].each do |day|
        create(:reporting_event, account: account, inbox: inbox, conversation: conversation, name: 'conversation_bot_handoff',
                                 created_at: Time.zone.parse("#{day} 10:00"))
      end

      series = service.execute(by: 'day', metrics: %w[bot_handoffs_count], **week)[:metrics].first

      expect(series[:points].sum { |point| point[:value] }).to eq(2)
      expect(series[:total_or_average]).to eq(1)
    end

    it 'marks weeks cut by since or until as partial' do
      result = service.execute(by: 'week', metrics: %w[conversations_count], **week)

      expect(result[:metrics].first[:points]).to eq([{ period: '2026-09-07 to 2026-09-12', partial: true, value: 3 },
                                                     { period: '2026-09-13 to 2026-09-13', partial: true, value: 0 }])
    end

    it 'returns the summary for each agent with activity, counts the others, and charts a single agent when asked' do
      result = service.execute(by: 'agent', metrics: %w[conversations_count], chart: true, **week)

      expect(result[:rows]).to contain_exactly(include(id: agent.id, name: agent.name, conversations: 3))
      expect(result[:without_activity]).to eq(1)
      expect(result[:chart_data].first[:series].first[:data]).to eq([3])
    end

    it 'lists an agent in the summary who only replied to older conversations' do
      replier = create(:user, account: account)
      older = create(:conversation, account: account, inbox: inbox, assignee: replier, created_at: Time.zone.parse('2026-08-03 10:00'))
      create(:reporting_event, name: 'reply_time', value: 600, account: account, inbox: inbox, user: replier, conversation: older,
                               created_at: Time.zone.parse('2026-09-10 10:00'))

      result = service.execute(by: 'agent', metrics: %w[reply_time], **week)

      expect(result[:rows]).to include(include(id: replier.id, conversations: 0, avg_reply_time: '10 minutes'))
      expect(result[:without_activity]).to eq(1)
    end

    it 'ranks the summary by the first metric asked for, so the model never sorts written durations' do
      slow = create(:user, account: account)
      slow_conversation = create(:conversation, account: account, inbox: inbox, assignee: slow, created_at: Time.zone.parse('2026-09-10 10:00'))
      { slow => [slow_conversation, 3_600], agent => [Conversation.where(assignee: agent).first, 600] }.each do |user, (conversation, seconds)|
        create(:reporting_event, name: 'first_response', value: seconds, account: account, inbox: inbox, user: user,
                                 conversation: conversation, created_at: Time.zone.parse('2026-09-10 11:00'))
      end

      by_time = service.execute(by: 'agent', metrics: %w[avg_first_response_time], **week)
      by_count = service.execute(by: 'agent', metrics: %w[conversations_count], **week)

      expect(by_time[:rows].pluck(:id)).to eq([slow.id, agent.id])
      expect(by_count[:rows].pluck(:id)).to eq([agent.id, slow.id])
    end

    it 'ranks from the lowest when asked, and lists an agent without a first response time last either way' do
      replied = create(:user, account: account)
      conversation = create(:conversation, account: account, inbox: inbox, assignee: replied, created_at: Time.zone.parse('2026-09-10 10:00'))
      create(:reporting_event, name: 'first_response', value: 600, account: account, inbox: inbox, user: replied,
                               conversation: conversation, created_at: Time.zone.parse('2026-09-10 11:00'))

      slow = create(:user, account: account)
      slow_conversation = create(:conversation, account: account, inbox: inbox, assignee: slow, created_at: Time.zone.parse('2026-09-10 10:00'))
      create(:reporting_event, name: 'first_response', value: 3_600, account: account, inbox: inbox, user: slow,
                               conversation: slow_conversation, created_at: Time.zone.parse('2026-09-10 11:00'))

      highest = service.execute(by: 'agent', metrics: %w[avg_first_response_time], **week)[:rows]
      lowest = service.execute(by: 'agent', metrics: %w[avg_first_response_time], order: 'lowest', **week)[:rows]

      expect(highest.pluck(:id)).to eq([slow.id, replied.id, agent.id])
      expect(lowest.map { |row| row.values_at(:id, :avg_first_response_time) })
        .to eq([[replied.id, '10 minutes'], [slow.id, '1 hour'], [agent.id, nil]])
    end

    it 'counts a label without activity instead of listing it with zero times' do
      create(:label, account: account, title: 'unused')

      result = service.execute(by: 'label', metrics: %w[conversations_count], **week)

      expect(result).to include(rows: [], without_activity: 1)
    end

    it 'says why no chart was drawn when every value is zero' do
      result = service.execute(by: 'agent', metrics: %w[resolutions_count], chart: true, **week)

      expect(result).to include(chart_note: include('no value in the range is above zero'))
      expect(result).not_to include(:chart)
    end

    it 'breaks a metric down per period for each agent with activity' do
      result = service.execute(by: 'day', metrics: %w[conversations_count], each: 'agent', **week)

      expect(result[:rows]).to contain_exactly(include(id: agent.id, total_or_average: 3))
    end

    it 'picks the breakdown rows by the metric, so an agent who only replied to older conversations is listed' do
      replier = create(:user, account: account)
      older = create(:conversation, account: account, inbox: inbox, assignee: replier, created_at: Time.zone.parse('2026-08-03 10:00'))
      create(:message, account: account, inbox: inbox, conversation: older, sender: replier, message_type: :outgoing,
                       created_at: Time.zone.parse('2026-09-10 10:00'))

      result = service.execute(by: 'day', metrics: %w[outgoing_messages_count], each: 'agent', **week)

      expect(result[:rows]).to contain_exactly(include(id: replier.id, total_or_average: 1))
    end

    it 'checks the agents with the most messages sent for messages sent, and says how many it left out' do
      stub_const('Captain::Copilot::ReportService::MAX_CHECKED', 1)
      replier = create(:user, account: account)
      older = create(:conversation, account: account, inbox: inbox, created_at: Time.zone.parse('2026-08-03 10:00'))
      [agent, replier, replier].each do |sender|
        create(:message, account: account, inbox: inbox, conversation: older, sender: sender, message_type: :outgoing,
                         created_at: Time.zone.parse('2026-09-10 10:00'))
      end

      result = service.execute(by: 'day', metrics: %w[outgoing_messages_count], each: 'agent', **week)

      expect(result[:rows]).to contain_exactly(include(id: replier.id, total_or_average: 2))
      expect(result[:note]).to eq('Checked the 1 busiest of 2 agents.')
    end

    it 'keeps the year in chart labels when the dates span years' do
      result = service.execute(by: 'year', metrics: %w[conversations_count], chart: true, since: '2025-01-01', until: '2026-12-31')

      expect(result[:chart_data].first[:categories]).to eq(['1 Jan 2025', '1 Jan 2026'])
    end

    it 'reports an argument the tool does not take instead of ignoring it' do
      result = service.call(by: 'day', metrics: %w[conversations_count], metric: 'conversations_count', **week)

      expect(result[:error]).to include('metric is not allowed here')
    end

    it 'rejects more than one agent, inbox, team or label' do
      expect { service.execute(by: 'day', metrics: %w[conversations_count], agent_id: agent.id, inbox_id: inbox.id, **week) }
        .to raise_error(ArgumentError, /at most one/)
    end

    it 'rejects an option the chosen report would leave out instead of answering without it' do
      expect { service.execute(by: 'agent', metrics: %w[resolutions_count], inbox_id: inbox.id, **week) }
        .to raise_error(ArgumentError, 'by agent does not take inbox_id')
      expect { service.execute(by: 'range', metrics: %w[conversations_count], chart: true, **week) }
        .to raise_error(ArgumentError, 'by range does not take chart')
      expect { service.execute(by: 'agent', metrics: %w[avg_first_response_time], chart: true, **week) }
        .to raise_error(ArgumentError, /needs conversations_count or resolutions_count/)
    end
  end
end
