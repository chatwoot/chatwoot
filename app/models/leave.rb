# frozen_string_literal: true

# == Schema Information
#
# Table name: leaves
#
#  id              :bigint           not null, primary key
#  approved_at     :datetime
#  end_date        :date             not null
#  leave_type      :integer          default("vacation"), not null
#  reason          :text
#  start_date      :date             not null
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  account_user_id :bigint           not null
#  approved_by_id  :bigint
#
# Indexes
#
#  index_leaves_on_account_and_status      (account_id,status)
#  index_leaves_on_account_id              (account_id)
#  index_leaves_on_account_user_and_dates  (account_user_id,start_date,end_date)
#  index_leaves_on_account_user_id         (account_user_id)
#  index_leaves_on_approved_by_id          (approved_by_id)
#  index_leaves_on_end_date                (end_date)
#  index_leaves_on_start_date              (start_date)
#  index_leaves_on_status                  (status)
#

class Leave < ApplicationRecord
  belongs_to :account
  belongs_to :account_user
  belongs_to :approved_by, class_name: 'User', optional: true

  has_one :user, through: :account_user

  enum leave_type: {
    vacation: 0,
    sick: 1,
    personal: 2,
    maternity: 3,
    paternity: 4,
    bereavement: 5,
    unpaid: 6
  }

  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2,
    cancelled: 3
  }

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :leave_type, presence: true
  validates :status, presence: true
  validate :end_date_after_start_date
  validate :no_overlapping_leaves, if: :approved?

  scope :active, -> { approved.where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :upcoming, -> { approved.where('start_date > ?', Date.current) }
  scope :past, -> { where('end_date < ?', Date.current) }
  scope :by_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }

  before_update :set_approved_at, if: -> { status_changed? && approved? }

  def active?
    approved? && start_date <= Date.current && end_date >= Date.current
  end

  def days_count
    return 0 unless start_date && end_date

    (end_date - start_date).to_i + 1
  end

  def overlaps_with?(other_leave)
    return false if other_leave == self

    start_date <= other_leave.end_date && end_date >= other_leave.start_date
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'must be after or equal to start date') if end_date < start_date
  end

  def no_overlapping_leaves
    overlapping_leaves = account_user.leaves
                                     .approved
                                     .where.not(id: id)
                                     .by_date_range(start_date, end_date)

    return unless overlapping_leaves.exists?

    errors.add(:base, 'Leave dates overlap with an existing approved leave')
  end

  def set_approved_at
    self.approved_at = Time.current
  end
end
