# == Schema Information
#
# Table name: ai_agent_selected_labels
#
#  id              :bigint           not null, primary key
#  label_condition :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  ai_agent_id     :bigint
#  label_id        :bigint
#
# Indexes
#
#  index_ai_agent_selected_labels_on_ai_agent_id  (ai_agent_id)
#  index_ai_agent_selected_labels_on_label_id     (label_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_agent_id => ai_agents.id)
#  fk_rails_...  (label_id => labels.id)
#
class AiAgentSelectedLabel < ApplicationRecord
  belongs_to :ai_agent, optional: true
  belongs_to :label, optional: true
end
