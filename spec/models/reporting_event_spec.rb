require 'rails_helper'

RSpec.describe ReportingEvent do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:conversation).optional }
  end

  describe '.distinct_resolutions' do
    let(:account) { create(:account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:agent1) { create(:user, account: account) }
    let(:agent2) { create(:user, account: account) }
    let(:resolved_at) { 1.hour.ago }

    let!(:first_row) { create_resolution(agent1, resolved_at) }
    let!(:second_row) { create_resolution(agent2, resolved_at) }
    let!(:later_resolution) { create_resolution(agent1, 10.minutes.ago) }
    let!(:reply_event) { create(:reporting_event, account: account, conversation: conversation, name: 'reply_time') }

    def create_resolution(user, ended_at)
      create(:reporting_event, account: account, conversation: conversation, user: user, name: 'conversation_resolved',
                               event_start_time: ended_at - 1.hour, event_end_time: ended_at)
    end

    it 'keeps one row per resolution and leaves other events untouched' do
      expect(account.reporting_events.distinct_resolutions).to contain_exactly(first_row, later_resolution, reply_event)
    end

    it 'dedupes within the filtered agents' do
      events = account.reporting_events.where(user_id: agent2.id).distinct_resolutions(user_ids: [agent2.id])

      expect(events).to contain_exactly(second_row)
    end
  end
end
