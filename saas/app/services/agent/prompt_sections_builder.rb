# frozen_string_literal: true

# Assembles the 7-part structured prompt sections into a single system prompt.
#
# The prompt sections are stored in `ai_agent.config['prompt_sections']`:
#   - initial_message    — Greeting text sent at conversation start
#   - instructions       — Behavioral directives (what the assistant does)
#   - general_context    — Static knowledge about the business
#   - success_criteria   — When to consider the conversation successful
#   - interruption_rules — When to escalate to a human
#   - inactivity_config  — { timeout_minutes, message }
#   - error_message      — Fallback for technical failures
#
# Usage:
#   builder = Agent::PromptSectionsBuilder.new(ai_agent)
#   system_prompt = builder.build
#
class Agent::PromptSectionsBuilder
  SECTION_HEADERS = {
    'instructions' => '## Instructions',
    'general_context' => '## Business Context',
    'success_criteria' => '## Success Criteria',
    'interruption_rules' => '## Escalation Rules',
    'inactivity_config' => '## Inactivity Handling',
    'error_message' => '## Error Handling'
  }.freeze

  def initialize(ai_agent)
    @ai_agent = ai_agent
    @sections = ai_agent.config&.dig('prompt_sections') || {}
  end

  def build
    return nil if @sections.blank?

    parts = []
    parts << build_instructions
    parts << build_general_context
    parts << build_success_criteria
    parts << build_interruption_rules
    parts << build_inactivity
    parts << build_error_message
    parts.compact.join("\n\n")
  end

  def sections?
    @sections.present? && @sections.values.any?(&:present?)
  end

  def initial_message
    @sections['initial_message'].presence
  end

  def error_message
    @sections['error_message'].presence
  end

  def inactivity_timeout_minutes
    @sections.dig('inactivity_config', 'timeout_minutes').to_i
  end

  def inactivity_message
    @sections.dig('inactivity_config', 'message').presence
  end

  private

  def build_instructions
    return nil if @sections['instructions'].blank?

    "#{SECTION_HEADERS['instructions']}\n#{@sections['instructions']}"
  end

  def build_general_context
    return nil if @sections['general_context'].blank?

    "#{SECTION_HEADERS['general_context']}\n#{@sections['general_context']}"
  end

  def build_success_criteria
    return nil if @sections['success_criteria'].blank?

    "#{SECTION_HEADERS['success_criteria']}\n#{@sections['success_criteria']}"
  end

  def build_interruption_rules
    return nil if @sections['interruption_rules'].blank?

    "#{SECTION_HEADERS['interruption_rules']}\n#{@sections['interruption_rules']}"
  end

  def build_inactivity
    config = @sections['inactivity_config']
    return nil if config.blank?

    timeout = config['timeout_minutes']
    message = config['message']
    return nil if timeout.blank? && message.blank?

    lines = [SECTION_HEADERS['inactivity_config']]
    lines << "Timeout: #{timeout} minutes" if timeout.present?
    lines << "Message to send on timeout: #{message}" if message.present?
    lines.join("\n")
  end

  def build_error_message
    return nil if @sections['error_message'].blank?

    "#{SECTION_HEADERS['error_message']}\nWhen a technical error occurs, respond with: #{@sections['error_message']}"
  end
end
