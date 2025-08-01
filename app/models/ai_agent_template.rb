# == Schema Information
#
# Table name: ai_agent_templates
#
#  id                  :bigint           not null, primary key
#  agent_type          :string           default("SINGLE_AGENT"), not null
#  description         :string           default("")
#  handover_prompt     :text
#  name                :string
#  source_type         :string           default("FLOWISE"), not null
#  store_config        :jsonb            not null
#  system_prompt       :text             not null
#  system_prompt_rules :text
#  template            :jsonb            not null
#  welcoming_message   :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  name_id             :string           default(""), not null
#
class AiAgentTemplate < ApplicationRecord
  validates :name, :system_prompt, presence: true
end
