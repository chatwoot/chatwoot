require 'rails_helper'

RSpec.describe Captain::Tools::Copilot::GetReportService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, :administrator, account: account) }
  let(:agent) { create(:user, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:service) { described_class.new(assistant, user: admin).tap { |tool| tool.tool_call = instance_double(CopilotToolCall, id: 7) } }
  let(:week) { { since: '2026-09-07T00:00:00Z', before: '2026-09-14T00:00:00Z' } }

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

    it 'totals each metric over exactly the dates given' do
      result = service.execute(by: 'range', metrics: %w[conversations_count], since: '2026-09-08T00:00:00Z', before: '2026-09-09T00:00:00Z')

      expect(result[:metrics]).to eq([{ metric: 'conversations_count', total_or_average: 1, data_from: '2026-09-08', data_to: '2026-09-08' }])
    end

    it 'marks weeks cut by since or before as partial' do
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

    it 'says why no chart was drawn when every value is zero' do
      result = service.execute(by: 'agent', metrics: %w[resolutions_count], chart: true, **week)

      expect(result).to include(chart_note: include('no value in the range is above zero'))
      expect(result).not_to include(:chart)
    end

    it 'breaks a metric down per period for each agent with activity' do
      result = service.execute(by: 'day', metrics: %w[conversations_count], each: 'agent', **week)

      expect(result[:rows]).to contain_exactly(include(id: agent.id, total_or_average: 3))
    end

    it 'reports an argument the tool does not take instead of ignoring it' do
      result = service.call(by: 'day', metrics: %w[conversations_count], metric: 'conversations_count', **week)

      expect(result[:error]).to include('metric is not allowed here')
    end

    it 'rejects more than one agent, inbox, team or label' do
      expect { service.execute(by: 'day', metrics: %w[conversations_count], agent_id: agent.id, inbox_id: inbox.id, **week) }
        .to raise_error(ArgumentError, /at most one/)
    end
  end
end
