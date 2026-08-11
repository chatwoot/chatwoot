# == Schema Information
#
# Table name: sla_policies
#
#  id                            :bigint           not null, primary key
#  description                   :string
#  first_response_time_threshold :float
#  name                          :string           not null
#  next_response_time_threshold  :float
#  notify_user_ids               :bigint           default([]), is an Array
#  only_during_business_hours    :boolean          default(FALSE)
#  resolution_time_threshold     :float
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :bigint           not null
#
# Indexes
#
#  index_sla_policies_on_account_id  (account_id)
#
class SlaPolicy < ApplicationRecord
  belongs_to :account
  validates :name, presence: true
  validate :notify_users_are_administrators

  has_many :conversations, dependent: :nullify
  has_many :applied_slas, dependent: :destroy_async

  before_validation :sanitize_notify_user_ids

  # Users alerted when this SLA is breached. Defaults to every administrator in the account
  # when no specific administrators are configured.
  def notify_users
    return account.administrators if notify_user_ids.blank?

    account.administrators.where(id: notify_user_ids)
  end

  def push_event_data
    {
      id: id,
      name: name,
      frt: first_response_time_threshold,
      nrt: next_response_time_threshold,
      rt: resolution_time_threshold
    }
  end

  private

  def sanitize_notify_user_ids
    self.notify_user_ids = Array(notify_user_ids).compact_blank.map(&:to_i).uniq
  end

  def notify_users_are_administrators
    return if notify_user_ids.blank?
    return if account.administrators.where(id: notify_user_ids).count == notify_user_ids.size

    errors.add(:notify_user_ids, 'must be administrators of the account')
  end
end
