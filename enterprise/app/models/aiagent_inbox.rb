# == Schema Information
#
# Table name: aiagent_inboxes
#
#  id                   :bigint           not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  aiagent_assistant_id :bigint           not null
#  inbox_id             :bigint           not null
#
# Indexes
#
#  index_aiagent_inboxes_on_aiagent_assistant_id               (aiagent_assistant_id)
#  index_aiagent_inboxes_on_aiagent_assistant_id_and_inbox_id  (aiagent_assistant_id,inbox_id) UNIQUE
#  index_aiagent_inboxes_on_inbox_id                           (inbox_id)
#
class AiagentInbox < ApplicationRecord
  belongs_to :aiagent_assistant, class_name: 'Aiagent::Assistant'
  belongs_to :inbox

  validates :inbox_id, uniqueness: true
end
