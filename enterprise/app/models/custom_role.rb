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
# - 'contact_manage': Can access all contacts in the account.
# - 'contact_inbox_manage': Can access contacts from assigned inboxes only.
# - 'contact_edit': Can edit contacts.
# - 'contact_delete': Can delete contacts.
# - 'report_manage': Can access all reports.
# - 'report_*': Can access a specific reports page.
# - 'knowledge_base_manage': Can manage knowledge base portals.

class CustomRole < ApplicationRecord
  belongs_to :account
  has_many :account_users, dependent: :nullify

  before_destroy :capture_filtered_unread_count_user_ids, prepend: true
  after_update_commit :invalidate_filtered_unread_count_visibility_update, if: :filtered_unread_count_permissions_changed?
  after_destroy_commit :invalidate_filtered_unread_count_visibility_destroy

  PERMISSIONS = %w[
    conversation_manage
    conversation_unassigned_manage
    conversation_participating_manage
    contact_manage
    contact_inbox_manage
    contact_edit
    contact_delete
    report_manage
    report_overview
    report_conversation
    report_agent
    report_agent_activity
    report_inbox
    report_team
    report_label
    report_csat
    report_sla
    report_bot
    report_queued_customers
    knowledge_base_manage
  ].freeze

  validates :name, presence: true
  validates :permissions, inclusion: { in: PERMISSIONS }

  private

  def filtered_unread_count_permissions_changed?
    previous_changes.key?('permissions')
  end

  def capture_filtered_unread_count_user_ids
    @filtered_unread_count_user_ids = account_users.pluck(:user_id)
  end

  def invalidate_filtered_unread_count_visibility_update
    invalidate_filtered_unread_count_visibility(account_users.pluck(:user_id))
  end

  def invalidate_filtered_unread_count_visibility_destroy
    invalidate_filtered_unread_count_visibility(@filtered_unread_count_user_ids)
  end

  def invalidate_filtered_unread_count_visibility(user_ids)
    invalidator = ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account)
    visibility_changed = invalidator.users_visibility_changed!(user_ids: user_ids)

    dispatch_account_cache_invalidated if visibility_changed
  end

  def dispatch_account_cache_invalidated
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CACHE_INVALIDATED, Time.zone.now, account: account, cache_keys: account.cache_keys)
  end
end
