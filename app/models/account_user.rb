# == Schema Information
#
# Table name: account_users
#
#  id                       :bigint           not null, primary key
#  active_at                :datetime
#  auto_offline             :boolean          default(TRUE), not null
#  availability             :integer          default("online"), not null
#  role                     :integer          default("agent")
#  timezone                 :string           default("UTC")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  account_id               :bigint
#  agent_capacity_policy_id :bigint
#  custom_role_id           :bigint
#  inviter_id               :bigint
#  user_id                  :bigint
#
# Indexes
#
#  index_account_users_on_account_id                (account_id)
#  index_account_users_on_agent_capacity_policy_id  (agent_capacity_policy_id)
#  index_account_users_on_custom_role_id            (custom_role_id)
#  index_account_users_on_user_id                   (user_id)
#  uniq_user_id_per_account_id                      (account_id,user_id) UNIQUE
#

class AccountUser < ApplicationRecord
  include AvailabilityStatusable
  include OutOfOffisable

  belongs_to :account
  belongs_to :user
  belongs_to :inviter, class_name: 'User', optional: true
  belongs_to :responsible, class_name: 'AccountUser', optional: true, inverse_of: :subordinates

  has_many :subordinates, class_name: 'AccountUser', foreign_key: 'responsible_id', dependent: :nullify, inverse_of: :responsible

  enum role: { agent: 0, administrator: 1, supervisor: 2 }
  enum availability: { online: 0, offline: 1, busy: 2 }

  accepts_nested_attributes_for :account

  after_create_commit :notify_creation, :create_notification_setting
  after_destroy :notify_deletion, :remove_user_from_account
  after_save :update_presence_in_redis, if: :saved_change_to_availability?

  validates :user_id, uniqueness: { scope: :account_id }
  validate :responsible_cannot_be_self
  validate :responsible_must_be_from_same_account

  def create_notification_setting
    setting = user.notification_settings.new(account_id: account.id)
    setting.selected_email_flags = [:email_conversation_assignment]
    setting.selected_push_flags = [:push_conversation_assignment]
    setting.save!
  end

  def remove_user_from_account
    ::Agents::DestroyJob.perform_later(account, user)
  end

  def permissions
    return ['administrator'] if administrator?
    return ['supervisor'] if supervisor?

    ['agent']
  end

  def subordinate_user_ids
    subordinates.pluck(:user_id)
  end

  def all_subordinate_user_ids(visited = Set.new)
    return [] if visited.include?(id)

    visited.add(id)
    ids = subordinate_user_ids
    subordinates.includes(:subordinates).each do |sub|
      ids += sub.all_subordinate_user_ids(visited) if sub.supervisor?
    end
    ids.uniq
  end

  def push_event_data
    {
      id: id,
      availability: availability,
      role: role,
      user_id: user_id
    }
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(AGENT_ADDED, Time.zone.now, account: account, user: user)
  end

  def notify_deletion
    Rails.configuration.dispatcher.dispatch(AGENT_REMOVED, Time.zone.now, account: account)
  end

  def update_presence_in_redis
    OnlineStatusTracker.set_status(account.id, user.id, availability)
  end

  def responsible_cannot_be_self
    return unless responsible_id.present? && responsible_id == id

    errors.add(:responsible_id, 'cannot be yourself')
  end

  def responsible_must_be_from_same_account
    return unless responsible_id.present? && responsible.present?
    return if responsible.account_id == account_id

    errors.add(:responsible_id, 'must be from the same account')
  end
end

AccountUser.prepend_mod_with('AccountUser')
AccountUser.include_mod_with('Audit::AccountUser')
AccountUser.include_mod_with('Concerns::AccountUser')
