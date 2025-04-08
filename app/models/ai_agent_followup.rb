# == Schema Information
#
# Table name: ai_agent_followups
#
#  id                             :bigint           not null, primary key
#  delay                          :integer          default(5)
#  handoff_to_agent_after_sending :boolean          default(FALSE), not null
#  prompts                        :text             not null
#  send_as_exact_message          :boolean          default(FALSE), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  ai_agent_id                    :bigint           not null
#
# Indexes
#
#  index_ai_agent_followups_on_ai_agent_id  (ai_agent_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_agent_id => ai_agents.id)
#
class AiAgentFollowup < ApplicationRecord
  belongs_to :ai_agent

  validates :prompts, presence: true
end
