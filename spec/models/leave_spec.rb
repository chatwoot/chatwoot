# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Leave, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:account_user) }
    it { is_expected.to belong_to(:approved_by).class_name('User').optional }
    it { is_expected.to have_one(:user).through(:account_user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
    it { is_expected.to validate_presence_of(:leave_type) }
    it { is_expected.to validate_presence_of(:status) }

    describe 'end_date_after_start_date' do
      let(:leave) { build(:leave, start_date: Date.current, end_date: Date.current - 1.day) }

      it 'validates end date is after start date' do
        expect(leave).not_to be_valid
        expect(leave.errors[:end_date]).to include('must be after or equal to start date')
      end
    end

    describe 'no_overlapping_leaves' do
      let(:account_user) { create(:account_user) }
      let(:new_leave) do
        build(:leave, account_user: account_user, start_date: Date.current + 3.days, end_date: Date.current + 10.days, status: 'approved')
      end

      before { create(:leave, :approved, account_user: account_user, start_date: Date.current, end_date: Date.current + 7.days) }

      it 'prevents overlapping approved leaves' do
        expect(new_leave).not_to be_valid
        expect(new_leave.errors[:base]).to include('Leave dates overlap with an existing approved leave')
      end

      it 'allows overlapping pending leaves' do
        new_leave.status = 'pending'
        expect(new_leave).to be_valid
      end
    end
  end

  describe 'enums' do
    it {
      expect(subject).to define_enum_for(:leave_type).with_values(vacation: 0, sick: 1, personal: 2, maternity: 3, paternity: 4, bereavement: 5,
                                                                  unpaid: 6)
    }

    it { is_expected.to define_enum_for(:status).with_values(pending: 0, approved: 1, rejected: 2, cancelled: 3) }
  end

  describe 'scopes' do
    let!(:active_leave) { create(:leave, :active) }
    let!(:upcoming_leave) { create(:leave, :future) }
    let!(:past_leave) { create(:leave, :past) }
    let!(:pending_leave) { create(:leave) }

    describe '.active' do
      it 'returns leaves that are currently active' do
        expect(described_class.active).to include(active_leave)
        expect(described_class.active).not_to include(upcoming_leave, past_leave, pending_leave)
      end
    end

    describe '.upcoming' do
      it 'returns approved leaves starting in the future' do
        expect(described_class.upcoming).to include(upcoming_leave)
        expect(described_class.upcoming).not_to include(active_leave, past_leave, pending_leave)
      end
    end

    describe '.past' do
      it 'returns leaves that have ended' do
        expect(described_class.past).to include(past_leave)
        expect(described_class.past).not_to include(active_leave, upcoming_leave, pending_leave)
      end
    end
  end

  describe '#active?' do
    it 'returns true for approved leaves within current date' do
      leave = build(:leave, :active)
      expect(leave.active?).to be true
    end

    it 'returns false for pending leaves' do
      leave = build(:leave)
      expect(leave.active?).to be false
    end

    it 'returns false for future leaves' do
      leave = build(:leave, :future)
      expect(leave.active?).to be false
    end
  end

  describe '#days_count' do
    it 'calculates the number of days' do
      leave = build(:leave, start_date: Date.current, end_date: Date.current + 6.days)
      expect(leave.days_count).to eq(7)
    end
  end

  describe '#overlaps_with?' do
    let(:leave1) { build(:leave, start_date: Date.current, end_date: Date.current + 7.days) }
    let(:leave2) { build(:leave, start_date: Date.current + 3.days, end_date: Date.current + 10.days) }
    let(:leave3) { build(:leave, start_date: Date.current + 8.days, end_date: Date.current + 15.days) }

    it 'returns true for overlapping leaves' do
      expect(leave1.overlaps_with?(leave2)).to be true
      expect(leave2.overlaps_with?(leave1)).to be true
    end

    it 'returns false for non-overlapping leaves' do
      expect(leave1.overlaps_with?(leave3)).to be false
      expect(leave3.overlaps_with?(leave1)).to be false
    end
  end

  describe 'callbacks' do
    describe 'set_approved_at' do
      let(:leave) { create(:leave) }

      it 'sets approved_at when status changes to approved' do
        expect(leave.approved_at).to be_nil
        leave.update!(status: 'approved')
        expect(leave.approved_at).to be_present
      end
    end
  end
end
