# == Schema Information
#
# Table name: ai_agent_templates
#
#  id                :bigint           not null, primary key
#  system_prompt     :text             not null
#  welcoming_message :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class AiAgentTemplate < ApplicationRecord
end
