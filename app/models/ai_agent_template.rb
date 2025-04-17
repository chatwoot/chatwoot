# == Schema Information
#
# Table name: ai_agent_templates
#
#  id                :bigint           not null, primary key
#  name              :string
#  system_prompt     :text             not null
#  template          :string(8192)
#  welcoming_message :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class AiAgentTemplate < ApplicationRecord
  validates :name, :system_prompt, presence: true
end
