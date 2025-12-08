# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QueueStatistic do
  describe 'validations' do
    subject { create(:queue_statistic) }

    it { is_expected.to validate_uniqueness_of(:date).scoped_to(:account_id) }

    it { is_expected.to validate_presence_of(:total_queued) }
    it { is_expected.to validate_presence_of(:total_assigned) }
    it { is_expected.to validate_presence_of(:total_left) }
    it { is_expected.to validate_presence_of(:average_wait_time_seconds) }
    it { is_expected.to validate_presence_of(:max_wait_time_seconds) }

    it { is_expected.to validate_numericality_of(:total_queued).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_assigned).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:total_left).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:average_wait_time_seconds).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:max_wait_time_seconds).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe '.update_statistics_for' do
    let(:account) { create(:account) }

    context 'when stats record does not exist' do
      it 'creates a new stat with queued count incremented' do
        expect do
          described_class.update_statistics_for(account.id, wait_time_seconds: 0)
        end.to change(described_class, :count).by(1)

        stat = described_class.last
        expect(stat.total_queued).to eq(1)
        expect(stat.total_assigned).to eq(0)
        expect(stat.total_left).to eq(0)
      end
    end

    context 'when assigned with wait time' do
      it 'updates averages and max wait time' do
        described_class.update_statistics_for(account.id, wait_time_seconds: 100, assigned: true)
        stat = described_class.last

        expect(stat.total_queued).to eq(1)
        expect(stat.total_assigned).to eq(1)
        expect(stat.average_wait_time_seconds).to eq(100)
        expect(stat.max_wait_time_seconds).to eq(100)
      end

      it 'properly averages multiple assigned events' do
        described_class.update_statistics_for(account.id, wait_time_seconds: 100, assigned: true)
        described_class.update_statistics_for(account.id, wait_time_seconds: 200, assigned: true)

        stat = described_class.last

        expect(stat.total_assigned).to eq(2)
        expect(stat.average_wait_time_seconds).to eq((100 + 200) / 2)
        expect(stat.max_wait_time_seconds).to eq(200)
      end
    end

    context 'when left without assignment' do
      it 'increments only left and queued' do
        described_class.update_statistics_for(account.id, wait_time_seconds: 0, left: true)
        stat = described_class.last

        expect(stat.total_queued).to eq(1)
        expect(stat.total_left).to eq(1)
        expect(stat.total_assigned).to eq(0)
      end
    end

    context 'when called repeatedly on same day' do
      it 'does not create duplicate records for same account/date' do
        described_class.update_statistics_for(account.id, wait_time_seconds: 0)
        described_class.update_statistics_for(account.id, wait_time_seconds: 0)

        stats = described_class.where(account_id: account.id, date: Date.current)
        expect(stats.count).to eq(1)
        expect(stats.first.total_queued).to eq(2)
      end
    end
  end
end
