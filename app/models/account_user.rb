# == Schema Information
#
# Table name: account_users
#
#  id           :bigint           not null, primary key
#  active_at    :datetime
#  auto_offline :boolean          default(TRUE), not null
#  availability :integer          default("online"), not null
#  role         :integer          default("agent")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#  inviter_id   :bigint
#  user_id      :bigint
#
# Indexes
#
#  index_account_users_on_account_id  (account_id)
#  index_account_users_on_user_id     (user_id)
#  uniq_user_id_per_account_id        (account_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

class AccountUser < ApplicationRecord
  include AvailabilityStatusable

  belongs_to :account
  belongs_to :user
  belongs_to :inviter, class_name: 'User', optional: true

  enum role: { agent: 0, administrator: 1 }
  enum availability: { online: 0, offline: 1, busy: 2 }

  accepts_nested_attributes_for :account

  after_create_commit :notify_creation, :create_notification_setting
  after_destroy :notify_deletion, :remove_user_from_account
  after_save :update_presence_in_redis, if: :saved_change_to_availability?

  validates :user_id, uniqueness: { scope: :account_id }

  def create_notification_setting
    setting = user.notification_settings.new(account_id: account.id)
    setting.selected_email_flags = [:email_conversation_assignment]
    setting.selected_push_flags = [:push_conversation_assignment]
    setting.save!
  end

  def remove_user_from_account
    ::Agents::DestroyService.new(account: account, user: user).perform
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(AGENT_ADDED, Time.zone.now, account: account)
  end

  def notify_deletion
    Rails.configuration.dispatcher.dispatch(AGENT_REMOVED, Time.zone.now, account: account)
  end

  def update_presence_in_redis
    OnlineStatusTracker.set_status(account.id, user.id, availability)
  end
end
