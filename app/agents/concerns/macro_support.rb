# frozen_string_literal: true

# Provides macro/automation support for conversation agents
module MacroSupport
  extend ActiveSupport::Concern

  private

  def macros_available? = available_macros.exists?

  def available_macros = current_account&.macros&.ai_available || Macro.none

  def macros_section
    return nil unless current_assistant&.feature_macros_enabled? && macros_available?

    macro_list = available_macros.select(:id, :name, :description).map do |macro|
      "* #{macro.id} | #{macro.name}: #{macro.description}"
    end.join("\n")

    <<~PROMPT
      #{section_header('MACROS / AUTOMATIONS')}

      * Trigger execute_macro ONLY when the user's intent is clear and unambiguous
      * Never trigger macros on partial or unclear requests
      * If intent is unclear, ask a short clarification question

      Available Macros:

      #{macro_list}
    PROMPT
  end
end
