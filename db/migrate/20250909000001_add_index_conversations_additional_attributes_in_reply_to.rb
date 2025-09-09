class AddIndexConversationsAdditionalAttributesInReplyTo < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Add GIN index for JSONB queries on conversations.additional_attributes->>'in_reply_to'
    # This index will significantly improve the performance of the query:
    # conversations.where("additional_attributes->>'in_reply_to' = ?", in_reply_to)
    # which is used in ImapMailbox#find_conversation_by_in_reply_to
    add_index :conversations, 
              "((additional_attributes->>'in_reply_to'))", 
              name: 'index_conversations_on_additional_attributes_in_reply_to',
              algorithm: :concurrently,
              where: "additional_attributes->>'in_reply_to' IS NOT NULL"
  end
end