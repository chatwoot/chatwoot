require 'rails_helper'

RSpec.describe LeaveRecord, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:approver) { create(:user, :administrator, account: account) }

  describe '#duration_in_days' do
    it 'calculates duration correctly for single day' do
      leave_record = create(:leave_record, start_date: Date.current, end_date: Date.current, status: :approved)
      expect(leave_record.duration_in_days).to eq(1)
    end

    it 'calculates duration correctly for multiple days' do
      leave_record = create(:leave_record, start_date: Date.current, end_date: Date.current + 4.days, status: :approved)
      expect(leave_record.duration_in_days).to eq(5)
    end

    it 'returns 0 when start_date is nil' do
      leave_record = build(:leave_record, start_date: nil, end_date: Date.current)
      expect(leave_record.duration_in_days).to eq(0)
    end

    it 'returns 0 when end_date is nil' do
      leave_record = build(:leave_record, start_date: Date.current, end_date: nil)
      expect(leave_record.duration_in_days).to eq(0)
    end
  end

  describe '#can_be_cancelled?' do
    context 'when leave record is pending' do
      it 'returns true' do
        leave_record = create(:leave_record, status: :pending)
        expect(leave_record.can_be_cancelled?).to be true
      end
    end

    context 'when leave record is approved' do
      it 'returns true for future leaves' do
        leave_record = create(:leave_record, status: :approved,
                                             start_date: 1.week.from_now.to_date,
                                             end_date: 2.weeks.from_now.to_date)
        expect(leave_record.can_be_cancelled?).to be true
      end

      it 'returns false for current leaves' do
        leave_record = create(:leave_record, status: :approved,
                                             start_date: Date.current,
                                             end_date: Date.current + 1.day)
        expect(leave_record.can_be_cancelled?).to be false
      end

      it 'returns false for past leaves' do
        leave_record = create(:leave_record, status: :approved,
                                             start_date: 1.week.ago.to_date,
                                             end_date: 3.days.ago.to_date)
        expect(leave_record.can_be_cancelled?).to be false
      end
    end

    context 'when leave record is rejected' do
      it 'returns false' do
        leave_record = create(:leave_record, status: :rejected)
        expect(leave_record.can_be_cancelled?).to be false
      end
    end

    context 'when leave record is cancelled' do
      it 'returns false' do
        leave_record = create(:leave_record, status: :cancelled)
        expect(leave_record.can_be_cancelled?).to be false
      end
    end
  end

  describe '#overlaps_with?' do
    let(:base_leave_record) do
      create(:leave_record, start_date: Date.current + 10.days,
                            end_date: Date.current + 15.days)
    end

    it 'returns false for non-LeaveRecord objects' do
      expect(base_leave_record.overlaps_with?('not a leave record')).to be false
    end

    it 'detects overlapping leave records - same dates' do
      overlapping_leave_record = build(:leave_record, start_date: Date.current + 10.days,
                                                      end_date: Date.current + 15.days)
      expect(base_leave_record.overlaps_with?(overlapping_leave_record)).to be true
    end

    it 'detects overlapping leave records - partial overlap start' do
      overlapping_leave_record = build(:leave_record, start_date: Date.current + 8.days,
                                                      end_date: Date.current + 12.days)
      expect(base_leave_record.overlaps_with?(overlapping_leave_record)).to be true
    end

    it 'detects overlapping leave records - partial overlap end' do
      overlapping_leave_record = build(:leave_record, start_date: Date.current + 13.days,
                                                      end_date: Date.current + 18.days)
      expect(base_leave_record.overlaps_with?(overlapping_leave_record)).to be true
    end

    it 'detects overlapping leave records - contained within' do
      overlapping_leave_record = build(:leave_record, start_date: Date.current + 12.days,
                                                      end_date: Date.current + 13.days)
      expect(base_leave_record.overlaps_with?(overlapping_leave_record)).to be true
    end

    it 'detects overlapping leave records - contains other' do
      overlapping_leave_record = build(:leave_record, start_date: Date.current + 8.days,
                                                      end_date: Date.current + 18.days)
      expect(base_leave_record.overlaps_with?(overlapping_leave_record)).to be true
    end

    it 'returns false for non-overlapping leave records - before' do
      non_overlapping_leave_record = build(:leave_record, start_date: Date.current + 5.days,
                                                          end_date: Date.current + 9.days)
      expect(base_leave_record.overlaps_with?(non_overlapping_leave_record)).to be false
    end

    it 'returns false for non-overlapping leave records - after' do
      non_overlapping_leave_record = build(:leave_record, start_date: Date.current + 16.days,
                                                          end_date: Date.current + 20.days)
      expect(base_leave_record.overlaps_with?(non_overlapping_leave_record)).to be false
    end

    it 'returns false for adjacent leave records - ending where other starts' do
      adjacent_leave_record = build(:leave_record, start_date: Date.current + 16.days,
                                                   end_date: Date.current + 20.days)
      expect(base_leave_record.overlaps_with?(adjacent_leave_record)).to be false
    end

    it 'returns false for adjacent leave records - starting where other ends' do
      adjacent_leave_record = build(:leave_record, start_date: Date.current + 5.days,
                                                   end_date: Date.current + 9.days)
      expect(base_leave_record.overlaps_with?(adjacent_leave_record)).to be false
    end
  end

  describe '#approve!' do
    let(:leave_record) { create(:leave_record, account: account, status: :pending) }

    before do
      # Ensure approver has administrator role in the account
      account_user = approver.account_users.find_by(account: account)
      account_user&.update!(role: :administrator)
    end

    it 'updates status to approved' do
      leave_record.approve!(approver)
      expect(leave_record.status).to eq('approved')
    end

    it 'sets approver' do
      leave_record.approve!(approver)
      expect(leave_record.approver).to eq(approver)
    end

    it 'sets approved_at timestamp' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      leave_record.approve!(approver)
      expect(leave_record.approved_at.to_i).to eq(freeze_time.to_i)
    end

    it 'raises error if approver is not admin' do
      non_admin = create(:user, account: account, role: :agent)

      expect do
        leave_record.approve!(non_admin)
      end.to raise_error(ActiveRecord::RecordInvalid, /must be an administrator/)
    end
  end

  describe '#reject!' do
    let(:leave_record) { create(:leave_record, account: account, status: :pending) }

    before do
      # Ensure approver has administrator role in the account
      account_user = approver.account_users.find_by(account: account)
      account_user&.update!(role: :administrator)
    end

    it 'updates status to rejected' do
      leave_record.reject!(approver)
      expect(leave_record.status).to eq('rejected')
    end

    it 'sets approver' do
      leave_record.reject!(approver)
      expect(leave_record.approver).to eq(approver)
    end

    it 'sets approved_at timestamp' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      leave_record.reject!(approver)
      expect(leave_record.approved_at.to_i).to eq(freeze_time.to_i)
    end

    it 'raises error if approver is not admin' do
      non_admin = create(:user, account: account, role: :agent)

      expect do
        leave_record.reject!(non_admin)
      end.to raise_error(ActiveRecord::RecordInvalid, /must be an administrator/)
    end
  end

  describe 'custom validations' do
    describe '#end_date_after_start_date' do
      it 'is valid when end_date is after start_date' do
        leave_record = build(:leave_record, start_date: 1.day.from_now.to_date, end_date: 2.days.from_now.to_date)
        expect(leave_record).to be_valid
      end

      it 'is valid when end_date equals start_date' do
        leave_record = build(:leave_record, start_date: 1.day.from_now.to_date, end_date: 1.day.from_now.to_date)
        expect(leave_record).to be_valid
      end

      it 'is invalid when end_date is before start_date' do
        leave_record = build(:leave_record, start_date: 2.days.from_now.to_date, end_date: 1.day.from_now.to_date)
        expect(leave_record).not_to be_valid
        expect(leave_record.errors[:end_date]).to include('must be after start date')
      end

      it 'skips validation when dates are nil' do
        leave_record = build(:leave_record, start_date: nil, end_date: nil)
        leave_record.valid?
        expect(leave_record.errors[:end_date]).not_to include('must be after start date')
      end
    end

    describe '#future_dates_for_pending_leaves' do
      it 'is valid for future start_date on pending leave record' do
        leave_record = build(:leave_record, status: :pending, start_date: Date.current + 1.day)
        expect(leave_record).to be_valid
      end

      it 'is invalid for current start_date on pending leave record' do
        leave_record = build(:leave_record, status: :pending, start_date: Date.current)
        expect(leave_record).not_to be_valid
        expect(leave_record.errors[:start_date]).to include('must be in the future')
      end

      it 'is invalid for past start_date on pending leave record' do
        leave_record = build(:leave_record, status: :pending, start_date: Date.current - 1.day)
        expect(leave_record).not_to be_valid
        expect(leave_record.errors[:start_date]).to include('must be in the future')
      end

      it 'skips validation for non-pending leave records' do
        leave_record = build(:leave_record, status: :approved, start_date: Date.current - 1.day)
        leave_record.valid?
        expect(leave_record.errors[:start_date]).not_to include('must be in the future')
      end
    end

    describe '#approver_is_admin' do
      let(:admin_user) { create(:user, :administrator, account: account) }
      let(:agent_user) { create(:user, account: account, role: :agent) }

      # Users are already associated with the account via factory

      it 'is valid with admin approver' do
        leave_record = build(:leave_record, account: account, approver: admin_user, status: :approved)
        expect(leave_record).to be_valid
      end

      it 'is invalid with non-admin approver' do
        leave_record = build(:leave_record, account: account, approver: agent_user, status: :approved)
        expect(leave_record).not_to be_valid
        expect(leave_record.errors[:approved_by]).to include('must be an administrator')
      end

      it 'skips validation when approver is nil' do
        leave_record = build(:leave_record, account: account, approver: nil)
        leave_record.valid?
        expect(leave_record.errors[:approved_by]).not_to include('must be an administrator')
      end
    end
  end
end
