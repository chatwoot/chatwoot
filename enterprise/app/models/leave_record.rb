# == Schema Information
#
# Table name: leave_records
#
#  id             :bigint           not null, primary key
#  approved_at    :datetime
#  end_date       :date             not null
#  leave_type     :integer          default("annual"), not null
#  reason         :text
#  start_date     :date             not null
#  status         :integer          default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  approved_by_id :bigint
#  user_id        :bigint           not null
#
# Indexes
#
#  index_leave_records_on_account_id             (account_id)
#  index_leave_records_on_account_id_and_status  (account_id,status)
#  index_leave_records_on_approved_by_id         (approved_by_id)
#  index_leave_records_on_user_id                (user_id)
#
class LeaveRecord < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :approver, class_name: 'User', foreign_key: 'approved_by_id', optional: true, inverse_of: :approved_leave_records

  enum leave_type: {
    annual: 0,
    sick: 1,
    personal: 2,
    maternity: 3,
    paternity: 4,
    emergency: 5,
    bereavement: 6,
    study: 7,
    other: 8
  }

  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2,
    cancelled: 3
  }

  validates :start_date, :end_date, presence: true
  validates :leave_type, :status, presence: true
  validate :end_date_after_start_date
  validate :future_dates_for_pending_leaves
  validate :approver_is_admin

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_leave_type, ->(leave_type) { where(leave_type: leave_type) }
  scope :in_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }

  def approve!(approver)
    update!(status: :approved, approved_by_id: approver.id, approved_at: Time.current)
  end

  def reject!(approver)
    update!(status: :rejected, approved_by_id: approver.id, approved_at: Time.current)
  end

  def duration_in_days
    return 0 unless start_date && end_date

    (end_date - start_date).to_i + 1
  end

  def can_be_cancelled?
    pending? || (approved? && start_date > Date.current)
  end

  def overlaps_with?(other_leave)
    return false unless other_leave.is_a?(LeaveRecord)

    start_date <= other_leave.end_date && end_date >= other_leave.start_date
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after start date') if end_date < start_date
  end

  def future_dates_for_pending_leaves
    return unless pending?

    errors.add(:start_date, 'must be in the future') if start_date && start_date <= Date.current
  end

  def approver_is_admin
    return unless approved_by_id && approver

    account_user = account.account_users.find_by(user: approver)
    errors.add(:approved_by, 'must be an administrator') unless account_user&.administrator?
  end
end
