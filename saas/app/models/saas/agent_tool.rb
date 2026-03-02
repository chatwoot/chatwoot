# frozen_string_literal: true

class Saas::AgentTool < ApplicationRecord
  self.table_name = 'agent_tools'

  belongs_to :ai_agent, class_name: 'Saas::AiAgent'
  belongs_to :account, class_name: '::Account'

  enum :tool_type, { http: 0, handoff: 1, built_in: 2 }

  encrypts :auth_token if Chatwoot.encryption_configured?

  validates :name, presence: true, length: { maximum: 255 }
  validate :url_template_not_obviously_internal, if: -> { url_template.present? && http? }

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

  private

  # Best-effort static check: block obviously internal URLs at save time.
  # Full SSRF validation with DNS resolution happens at runtime in ToolRunner.
  def url_template_not_obviously_internal
    # Strip Liquid tags so we can parse the URL skeleton
    stripped = url_template.gsub(/\{\{.*?\}\}/, 'PLACEHOLDER')
    uri = URI.parse(stripped)

    unless %w[http https].include?(uri.scheme&.downcase)
      errors.add(:url_template, 'must use http or https')
      return
    end

    return if uri.host.blank? # host is a Liquid variable — can only validate at runtime

    blocked_hosts = %w[localhost 127.0.0.1 0.0.0.0 ::1 169.254.169.254 metadata.google.internal]
    blocked_suffixes = %w[.local .internal]

    if blocked_hosts.include?(uri.host.downcase) || blocked_suffixes.any? { |s| uri.host.downcase.end_with?(s) }
      errors.add(:url_template, 'must not point to internal or private addresses')
    end
  rescue URI::InvalidURIError
    errors.add(:url_template, 'is not a valid URL')
  end
end
