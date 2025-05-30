# == Schema Information
#
# Table name: ai_agent_inboxes
#
#  id               :bigint           not null, primary key
#  ai_agent_topic_id :bigint           not null
#  inbox_id         :bigint           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_ai_agent_inboxes_on_ai_agent_topic_id                   (ai_agent_topic_id)
#  index_ai_agent_inboxes_on_inbox_id                           (inbox_id)
#  index_ai_agent_inboxes_on_ai_agent_topic_id_and_inbox_id     (ai_agent_topic_id,inbox_id) UNIQUE
#
class AIAgentInbox < ApplicationRecord
  self.table_name = 'ai_agent_inboxes'

  belongs_to :ai_agent_topic, class_name: 'AIAgent::Topic'
  belongs_to :inbox

  validates :inbox_id, uniqueness: { scope: :ai_agent_topic_id }
end 