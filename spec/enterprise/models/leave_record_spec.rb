require 'rails_helper'

RSpec.describe LeaveRecord, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:approved_by).class_name('User').optional }
  end

  describe 'validations' do
    subject { build(:leave_record, account: account, user: user) }

    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
    it { is_expected.to validate_presence_of(:leave_type) }
    it { is_expected.to validate_presence_of(:status) }

    it 'validates end_date is after start_date' do
      leave = build(:leave_record, account: account, user: user,
                                   start_date: Date.current + 2.days,
                                   end_date: Date.current)
      expect(leave).not_to be_valid
      expect(leave.errors[:end_date]).to include('must be after start date')
    end

    it 'validates future dates for pending leaves' do
      leave = build(:leave_record, account: account, user: user,
                                   status: :pending,
                                   start_date: Date.current)
      expect(leave).not_to be_valid
      expect(leave.errors[:start_date]).to include('must be in the future')
    end

    it 'validates approved_by is admin when present' do
      agent = create(:user, account: account, role: :agent)
      leave = build(:leave_record, account: account, user: user,
                                   approved_by: agent,
                                   status: :approved)
      expect(leave).not_to be_valid
      expect(leave.errors[:approved_by]).to include('must be an administrator')
    end
  end

  describe '#duration_in_days' do
    it 'calculates correct duration' do
      leave = build(:leave_record,
                    start_date: Date.current + 1.day,
                    end_date: Date.current + 5.days)
      expect(leave.duration_in_days).to eq(5)
    end
  end

  describe '#can_be_cancelled?' do
    it 'returns true for pending leaves' do
      leave = build(:leave_record, status: :pending)
      expect(leave.can_be_cancelled?).to be true
    end

    it 'returns true for approved future leaves' do
      leave = build(:leave_record, status: :approved,
                                   start_date: Date.current + 1.day)
      expect(leave.can_be_cancelled?).to be true
    end

    it 'returns false for approved ongoing leaves' do
      leave = build(:leave_record, status: :approved,
                                   start_date: Date.current)
      expect(leave.can_be_cancelled?).to be false
    end

    it 'returns false for rejected leaves' do
      leave = build(:leave_record, status: :rejected)
      expect(leave.can_be_cancelled?).to be false
    end
  end

  describe '#approve!' do
    let(:leave) { create(:leave_record, account: account, user: user, status: :pending) }

    it 'approves the leave and sets approved_by' do
      freeze_time do
        leave.approve!(admin)

        expect(leave.status).to eq('approved')
        expect(leave.approved_by).to eq(admin)
        expect(leave.approved_at).to eq(Time.current)
      end
    end
  end

  describe '#reject!' do
    let(:leave) { create(:leave_record, account: account, user: user, status: :pending) }

    it 'rejects the leave and sets approved_by' do
      freeze_time do
        leave.reject!(admin)

        expect(leave.status).to eq('rejected')
        expect(leave.approved_by).to eq(admin)
        expect(leave.approved_at).to eq(Time.current)
      end
    end
  end

  describe '#overlaps_with?' do
    let(:leave1) do
      build(:leave_record,
            start_date: Date.current + 5.days,
            end_date: Date.current + 10.days)
    end

    it 'detects overlapping leaves' do
      leave2 = build(:leave_record,
                     start_date: Date.current + 7.days,
                     end_date: Date.current + 12.days)
      expect(leave1.overlaps_with?(leave2)).to be true
    end

    it 'returns false for non-overlapping leaves' do
      leave2 = build(:leave_record,
                     start_date: Date.current + 11.days,
                     end_date: Date.current + 15.days)
      expect(leave1.overlaps_with?(leave2)).to be false
    end
  end
end
