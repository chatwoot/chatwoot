# == Schema Information
#
# Table name: conversation_assignments
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  assignee_id     :bigint           not null
#  conversation_id :bigint           not null
#  inbox_id        :bigint           not null
#  team_id         :bigint
#
# Indexes
#
#  index_conversation_assignments_on_account_id       (account_id)
#  index_conversation_assignments_on_assignee_id      (assignee_id)
#  index_conversation_assignments_on_conversation_id  (conversation_id)
#  index_conversation_assignments_on_inbox_id         (inbox_id)
#  index_conversation_assignments_on_team_id          (team_id)
#
class ConversationAssignment < ApplicationRecord
  validates :conversation, :account, :inbox, :assignee, presence: true

  belongs_to :conversation
  belongs_to :account
  belongs_to :inbox
  belongs_to :assignee, class_name: 'User'
  belongs_to :team, optional: true
end
