# == Schema Information
#
# Table name: custom_roles
#
#  id          :bigint           not null, primary key
#  description :string
#  name        :string
#  permissions :text             default([]), is an Array
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_custom_roles_on_account_id  (account_id)
#
#

# Available permissions for custom roles:
# - 'conversation_manage': Can manage all conversations.
# - 'conversation_unassigned_manage': Can manage unassigned conversations and assign to self.
# - 'conversation_participating_manage': Can manage conversations they are participating in (assigned to or a participant).
# - 'contact_manage': Can manage contacts.
# - 'report_manage': Can manage reports.
# - 'knowledge_base_manage': Can manage knowledge base portals.

class CustomRole < ApplicationRecord
  belongs_to :account
  has_many :account_users, dependent: :nullify

  before_destroy :cache_users_for_unread_filter_notification, prepend: true
  after_commit :notify_unread_filter_counts_changed, on: [:update, :destroy], if: :unread_filter_access_changed?

  PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    report_manage
    knowledge_base_manage
  ].freeze

  validates :name, presence: true
  validates :permissions, inclusion: { in: PERMISSIONS }

  private

  def unread_filter_access_changed?
    destroyed? || previous_changes.key?('permissions')
  end

  def cache_users_for_unread_filter_notification
    @users_for_unread_filter_notification = account_users.includes(:user).map(&:user)
  end

  def users_for_unread_filter_notification
    @users_for_unread_filter_notification || account_users.includes(:user).map(&:user)
  end

  def notify_unread_filter_counts_changed
    users_for_unread_filter_notification.each do |user|
      ::Conversations::UnreadCounts::UserFilterNotifier.new(account: account, user: user).perform
    end
  end
end
