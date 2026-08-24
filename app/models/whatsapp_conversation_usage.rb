# == Schema Information
#
# Table name: whatsapp_conversation_usages
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  inbox_id        :bigint           not null
#  message_id      :bigint           not null
#
# Indexes
#
#  idx_on_account_id_created_at_35e4aba0e8                (account_id,created_at)
#  index_whatsapp_conversation_usages_on_account_id       (account_id)
#  index_whatsapp_conversation_usages_on_conversation_id  (conversation_id)
#  index_whatsapp_conversation_usages_on_inbox_id         (inbox_id)
#  index_whatsapp_conversation_usages_on_message_id       (message_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#  fk_rails_...  (message_id => messages.id) ON DELETE => cascade
#
class WhatsappConversationUsage < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  belongs_to :conversation
  belongs_to :message
end
