# == Schema Information
#
# Table name: conversation_statuses
#
#  id              :bigint           not null, primary key
#  status          :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  inbox_id        :bigint           not null
#
# Indexes
#
#  index_conversation_statuses_on_account_id                      (account_id)
#  index_conversation_statuses_on_conversation_id                 (conversation_id)
#  index_conversation_statuses_on_conversation_id_and_created_at  (conversation_id,created_at)
#  index_conversation_statuses_on_inbox_id                        (inbox_id)
#
class ConversationStatus < ApplicationRecord
  validates :account, :inbox, :conversation, :status, presence: true

  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation

  enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }

  # Add any additional validations, scopes, or methods as needed
end
