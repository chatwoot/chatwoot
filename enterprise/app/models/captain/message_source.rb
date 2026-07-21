# == Schema Information
#
# Table name: captain_message_sources
#
#  id                    :bigint           not null, primary key
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  assistant_id          :bigint           not null
#  assistant_response_id :bigint           not null
#  conversation_id       :bigint           not null
#  document_id           :bigint           not null
#  message_id            :bigint           not null
#
# Indexes
#
#  idx_captain_message_sources_on_message_and_response  (message_id,assistant_response_id) UNIQUE
#  index_captain_message_sources_on_account_id          (account_id)
#  index_captain_message_sources_on_assistant_id        (assistant_id)
#  index_captain_message_sources_on_conversation_id     (conversation_id)
#  index_captain_message_sources_on_document_id         (document_id)
#  index_captain_message_sources_on_message_id          (message_id)
#
class Captain::MessageSource < ApplicationRecord
  self.table_name = 'captain_message_sources'

  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant'
  belongs_to :conversation, class_name: '::Conversation'
  belongs_to :message
  belongs_to :document, class_name: 'Captain::Document'
  belongs_to :assistant_response, class_name: 'Captain::AssistantResponse', optional: true
end
