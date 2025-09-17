# == Schema Information
#
# Table name: ai_agent_templates
#
#  id                  :bigint           not null, primary key
#  agent_type          :string           default(NULL), not null
#  description         :string           default("")
#  handover_prompt     :text
#  name                :string
#  source_type         :string           default("flowise"), not null
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

  enum source_type: { flowise: 'FLOWISE', jangkau: 'JANGKAU' }
  enum agent_type: { single_agent: 'single-agent', multi_agent: 'multi-agent', custom_agent: 'custom-agent' }

  scope :flowise, -> { where(source_type: :flowise) }
  scope :jangkau, -> { where(source_type: :jangkau) }
  scope :single_agent, -> { where(agent_type: :single_agent) }
  scope :multi_agent, -> { where(agent_type: :multi_agent) }
  scope :custom_agent, -> { where(agent_type: :custom_agent) }

  def self.agent_type_matches?(param_type, enum_key)
    agent_types[param_type] == agent_types[enum_key]
  end
end
