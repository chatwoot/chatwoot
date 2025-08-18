require 'rails_helper'

RSpec.describe Leave, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:approver) { create(:user, account: account, role: :administrator) }

  describe '#duration_in_days' do
    it 'calculates duration correctly for single day' do
      leave = create(:leave, start_date: Date.current, end_date: Date.current)
      expect(leave.duration_in_days).to eq(1)
    end

    it 'calculates duration correctly for multiple days' do
      leave = create(:leave, start_date: Date.current, end_date: Date.current + 4.days)
      expect(leave.duration_in_days).to eq(5)
    end

    it 'returns 0 when start_date is nil' do
      leave = build(:leave, start_date: nil, end_date: Date.current)
      expect(leave.duration_in_days).to eq(0)
    end

    it 'returns 0 when end_date is nil' do
      leave = build(:leave, start_date: Date.current, end_date: nil)
      expect(leave.duration_in_days).to eq(0)
    end
  end

  describe '#can_be_cancelled?' do
    context 'when leave is pending' do
      it 'returns true' do
        leave = create(:leave, status: :pending)
        expect(leave.can_be_cancelled?).to be true
      end
    end

    context 'when leave is approved' do
      it 'returns true for future leaves' do
        leave = create(:leave, status: :approved,
                               start_date: 1.week.from_now.to_date,
                               end_date: 2.weeks.from_now.to_date)
        expect(leave.can_be_cancelled?).to be true
      end

      it 'returns false for current leaves' do
        leave = create(:leave, status: :approved,
                               start_date: Date.current,
                               end_date: Date.current + 1.day)
        expect(leave.can_be_cancelled?).to be false
      end

      it 'returns false for past leaves' do
        leave = create(:leave, status: :approved,
                               start_date: 1.week.ago.to_date,
                               end_date: 3.days.ago.to_date)
        expect(leave.can_be_cancelled?).to be false
      end
    end

    context 'when leave is rejected' do
      it 'returns false' do
        leave = create(:leave, status: :rejected)
        expect(leave.can_be_cancelled?).to be false
      end
    end

    context 'when leave is cancelled' do
      it 'returns false' do
        leave = create(:leave, status: :cancelled)
        expect(leave.can_be_cancelled?).to be false
      end
    end
  end

  describe '#overlaps_with?' do
    let(:base_leave) do
      create(:leave, start_date: Date.current + 10.days,
                     end_date: Date.current + 15.days)
    end

    it 'returns false for non-Leave objects' do
      expect(base_leave.overlaps_with?('not a leave')).to be false
    end

    it 'detects overlapping leaves - same dates' do
      overlapping_leave = build(:leave, start_date: Date.current + 10.days,
                                        end_date: Date.current + 15.days)
      expect(base_leave.overlaps_with?(overlapping_leave)).to be true
    end

    it 'detects overlapping leaves - partial overlap start' do
      overlapping_leave = build(:leave, start_date: Date.current + 8.days,
                                        end_date: Date.current + 12.days)
      expect(base_leave.overlaps_with?(overlapping_leave)).to be true
    end

    it 'detects overlapping leaves - partial overlap end' do
      overlapping_leave = build(:leave, start_date: Date.current + 13.days,
                                        end_date: Date.current + 18.days)
      expect(base_leave.overlaps_with?(overlapping_leave)).to be true
    end

    it 'detects overlapping leaves - contained within' do
      overlapping_leave = build(:leave, start_date: Date.current + 12.days,
                                        end_date: Date.current + 13.days)
      expect(base_leave.overlaps_with?(overlapping_leave)).to be true
    end

    it 'detects overlapping leaves - contains other' do
      overlapping_leave = build(:leave, start_date: Date.current + 8.days,
                                        end_date: Date.current + 18.days)
      expect(base_leave.overlaps_with?(overlapping_leave)).to be true
    end

    it 'returns false for non-overlapping leaves - before' do
      non_overlapping_leave = build(:leave, start_date: Date.current + 5.days,
                                            end_date: Date.current + 9.days)
      expect(base_leave.overlaps_with?(non_overlapping_leave)).to be false
    end

    it 'returns false for non-overlapping leaves - after' do
      non_overlapping_leave = build(:leave, start_date: Date.current + 16.days,
                                            end_date: Date.current + 20.days)
      expect(base_leave.overlaps_with?(non_overlapping_leave)).to be false
    end

    it 'returns false for adjacent leaves - ending where other starts' do
      adjacent_leave = build(:leave, start_date: Date.current + 16.days,
                                     end_date: Date.current + 20.days)
      expect(base_leave.overlaps_with?(adjacent_leave)).to be false
    end

    it 'returns false for adjacent leaves - starting where other ends' do
      adjacent_leave = build(:leave, start_date: Date.current + 5.days,
                                     end_date: Date.current + 9.days)
      expect(base_leave.overlaps_with?(adjacent_leave)).to be false
    end
  end

  describe '#approve!' do
    let(:leave) { create(:leave, status: :pending) }

    before do
      create(:account_user, account: account, user: approver, role: :administrator)
    end

    it 'updates status to approved' do
      leave.approve!(approver)
      expect(leave.status).to eq('approved')
    end

    it 'sets approver' do
      leave.approve!(approver)
      expect(leave.approver).to eq(approver)
    end

    it 'sets approved_at timestamp' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      leave.approve!(approver)
      expect(leave.approved_at.to_i).to eq(freeze_time.to_i)
    end

    it 'raises error if approver is not admin' do
      non_admin = create(:user, account: account, role: :agent)
      create(:account_user, account: account, user: non_admin, role: :agent)

      expect do
        leave.approve!(non_admin)
      end.to raise_error(ActiveRecord::RecordInvalid, /must be an administrator/)
    end
  end

  describe '#reject!' do
    let(:leave) { create(:leave, status: :pending) }

    before do
      create(:account_user, account: account, user: approver, role: :administrator)
    end

    it 'updates status to rejected' do
      leave.reject!(approver)
      expect(leave.status).to eq('rejected')
    end

    it 'sets approver' do
      leave.reject!(approver)
      expect(leave.approver).to eq(approver)
    end

    it 'sets approved_at timestamp' do
      freeze_time = Time.current
      allow(Time).to receive(:current).and_return(freeze_time)

      leave.reject!(approver)
      expect(leave.approved_at.to_i).to eq(freeze_time.to_i)
    end

    it 'raises error if approver is not admin' do
      non_admin = create(:user, account: account, role: :agent)
      create(:account_user, account: account, user: non_admin, role: :agent)

      expect do
        leave.reject!(non_admin)
      end.to raise_error(ActiveRecord::RecordInvalid, /must be an administrator/)
    end
  end

  describe 'custom validations' do
    describe '#end_date_after_start_date' do
      it 'is valid when end_date is after start_date' do
        leave = build(:leave, start_date: Date.current, end_date: Date.current + 1.day)
        expect(leave).to be_valid
      end

      it 'is valid when end_date equals start_date' do
        leave = build(:leave, start_date: Date.current, end_date: Date.current)
        expect(leave).to be_valid
      end

      it 'is invalid when end_date is before start_date' do
        leave = build(:leave, start_date: Date.current + 1.day, end_date: Date.current)
        expect(leave).not_to be_valid
        expect(leave.errors[:end_date]).to include('must be after start date')
      end

      it 'skips validation when dates are nil' do
        leave = build(:leave, start_date: nil, end_date: nil)
        leave.valid?
        expect(leave.errors[:end_date]).not_to include('must be after start date')
      end
    end

    describe '#future_dates_for_pending_leaves' do
      it 'is valid for future start_date on pending leave' do
        leave = build(:leave, status: :pending, start_date: Date.current + 1.day)
        expect(leave).to be_valid
      end

      it 'is invalid for current start_date on pending leave' do
        leave = build(:leave, status: :pending, start_date: Date.current)
        expect(leave).not_to be_valid
        expect(leave.errors[:start_date]).to include('must be in the future')
      end

      it 'is invalid for past start_date on pending leave' do
        leave = build(:leave, status: :pending, start_date: Date.current - 1.day)
        expect(leave).not_to be_valid
        expect(leave.errors[:start_date]).to include('must be in the future')
      end

      it 'skips validation for non-pending leaves' do
        leave = build(:leave, status: :approved, start_date: Date.current - 1.day)
        leave.valid?
        expect(leave.errors[:start_date]).not_to include('must be in the future')
      end
    end

    describe '#approver_is_admin' do
      let(:admin_user) { create(:user, account: account, role: :administrator) }
      let(:agent_user) { create(:user, account: account, role: :agent) }

      before do
        create(:account_user, account: account, user: admin_user, role: :administrator)
        create(:account_user, account: account, user: agent_user, role: :agent)
      end

      it 'is valid with admin approver' do
        leave = build(:leave, account: account, approver: admin_user, status: :approved)
        expect(leave).to be_valid
      end

      it 'is invalid with non-admin approver' do
        leave = build(:leave, account: account, approver: agent_user, status: :approved)
        expect(leave).not_to be_valid
        expect(leave.errors[:approved_by]).to include('must be an administrator')
      end

      it 'skips validation when approver is nil' do
        leave = build(:leave, account: account, approver: nil)
        leave.valid?
        expect(leave.errors[:approved_by]).not_to include('must be an administrator')
      end
    end
  end
end
