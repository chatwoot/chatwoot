# frozen_string_literal: true

class Saas::AgentTool < ApplicationRecord
  self.table_name = 'agent_tools'

  belongs_to :ai_agent, class_name: 'Saas::AiAgent'
  belongs_to :account

  enum :tool_type, { http: 0, handoff: 1, built_in: 2 }

  validates :name, presence: true, length: { maximum: 255 }

  scope :active, -> { where(active: true) }

  # Render the tool definition in OpenAI function-calling format
  def to_llm_tool
    {
      type: 'function',
      function: {
        name: name.parameterize(separator: '_'),
        description: description,
        parameters: parameters_schema || {}
      }
    }
  end

  # Render URL template with Liquid variables
  def rendered_url(variables = {})
    Liquid::Template.parse(url_template).render(variables.stringify_keys)
  end

  # Render body template with Liquid variables
  def rendered_body(variables = {})
    return nil if body_template.blank?

    Liquid::Template.parse(body_template).render(variables.stringify_keys)
  end
end
