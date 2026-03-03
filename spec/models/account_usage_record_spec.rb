# == Schema Information
#
# Table name: account_usage_records
#
#  id                 :bigint           not null, primary key
#  ai_responses_count :integer          default(0), not null
#  bonus_credits      :integer          default(0), not null
#  overage_count      :integer          default(0), not null
#  period_date        :date             not null
#  voice_notes_count  :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  idx_usage_account_period  (account_id,period_date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
require 'rails_helper'

RSpec.describe AccountUsageRecord do
  let(:account) { create(:account) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    subject { build(:account_usage_record, account: account) }

    it { is_expected.to validate_presence_of(:period_date) }

    it 'enforces uniqueness of period_date scoped to account' do
      create(:account_usage_record, account: account, period_date: Date.new(2026, 3, 1))
      duplicate = build(:account_usage_record, account: account, period_date: Date.new(2026, 3, 1))
      expect(duplicate).not_to be_valid
    end

    it 'allows same period_date for different accounts' do
      other_account = create(:account)
      create(:account_usage_record, account: account, period_date: Date.new(2026, 3, 1))
      record = build(:account_usage_record, account: other_account, period_date: Date.new(2026, 3, 1))
      expect(record).to be_valid
    end
  end

  describe '.current_for' do
    it 'creates a new record for current month if none exists' do
      expect { described_class.current_for(account) }.to change(described_class, :count).by(1)

      record = described_class.current_for(account)
      expect(record.period_date).to eq(Time.current.beginning_of_month.to_date)
      expect(record.ai_responses_count).to eq(0)
      expect(record.voice_notes_count).to eq(0)
      expect(record.bonus_credits).to eq(0)
    end

    it 'returns existing record for current month' do
      existing = described_class.current_for(account)
      existing.update!(ai_responses_count: 42)

      found = described_class.current_for(account)
      expect(found.id).to eq(existing.id)
      expect(found.ai_responses_count).to eq(42)
    end

    it 'creates separate records for different months' do
      travel_to Time.zone.local(2026, 3, 15) do
        march_record = described_class.current_for(account)
        expect(march_record.period_date).to eq(Date.new(2026, 3, 1))
      end

      travel_to Time.zone.local(2026, 4, 1) do
        april_record = described_class.current_for(account)
        expect(april_record.period_date).to eq(Date.new(2026, 4, 1))
      end

      expect(described_class.where(account: account).count).to eq(2)
    end
  end

  describe '#increment_ai_responses!' do
    let(:record) { create(:account_usage_record, account: account) }

    it 'increments ai_responses_count by 1 by default' do
      expect { record.increment_ai_responses! }.to change { record.reload.ai_responses_count }.by(1)
    end

    it 'increments by a custom count' do
      expect { record.increment_ai_responses!(10) }.to change { record.reload.ai_responses_count }.by(10)
    end
  end

  describe '#increment_voice_notes!' do
    let(:record) { create(:account_usage_record, account: account) }

    it 'increments voice_notes_count by 1' do
      expect { record.increment_voice_notes! }.to change { record.reload.voice_notes_count }.by(1)
    end

    it 'also increments ai_responses_count by 6 per voice note' do
      expect { record.increment_voice_notes! }.to change { record.reload.ai_responses_count }.by(6)
    end

    it 'correctly scales for multiple voice notes' do
      record.increment_voice_notes!(3)
      record.reload
      expect(record.voice_notes_count).to eq(3)
      expect(record.ai_responses_count).to eq(18)
    end
  end
end
