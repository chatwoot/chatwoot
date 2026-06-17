# == Schema Information
#
# Table name: inbox_members
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  inbox_id   :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_inbox_members_on_inbox_id              (inbox_id)
#  index_inbox_members_on_inbox_id_and_user_id  (inbox_id,user_id) UNIQUE
#

class InboxMember < ApplicationRecord
  validates :inbox_id, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :inbox_id }

  belongs_to :user
  belongs_to :inbox

  after_create :add_agent_to_round_robin
  before_destroy :cache_unread_filter_notification_context
  after_destroy :remove_agent_from_round_robin
  after_commit :notify_unread_filter_counts_changed, on: [:create, :destroy]

  private

  def add_agent_to_round_robin
    ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox).add_agent_to_queue(user_id)
  end

  def remove_agent_from_round_robin
    ::AutoAssignment::InboxRoundRobinService.new(inbox: inbox).remove_agent_from_queue(user_id) if inbox.present?
  end

  def cache_unread_filter_notification_context
    @unread_filter_account = inbox&.account
    @unread_filter_user = user
  end

  def notify_unread_filter_counts_changed
    account = @unread_filter_account || inbox&.account
    ::Conversations::UnreadCounts::UserFilterNotifier.new(account: account, user: @unread_filter_user || user).perform
  end
end

InboxMember.include_mod_with('Audit::InboxMember')
