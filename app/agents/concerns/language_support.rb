# frozen_string_literal: true

# Provides language detection and preference rules for conversation agents
module LanguageSupport
  extend ActiveSupport::Concern

  private

  def language_section
    <<~PROMPT
      #{section_header('LANGUAGE RULES (HIGHEST PRIORITY)')}

      1. Detect the language of the user's LAST message
      2. Respond entirely in the SAME language
      3. If the user switches languages, switch immediately
      4. Do NOT mix languages in a single response
      5. Exceptions: brand names, product names, technical terms with no natural translation
      #{preferred_language_instruction}
    PROMPT
  end

  def preferred_language_instruction
    parts = [default_language_rule, arabic_dialect_rule].compact
    return '' if parts.empty?

    "\n#{parts.join("\n")}"
  end

  def default_language_rule
    return nil if current_assistant&.language.blank? || current_assistant.language == 'en'

    "6. If the user's language is ambiguous, default to #{current_assistant.language_name}"
  end

  def arabic_dialect_rule
    return nil unless current_assistant&.language == 'ar' && current_assistant&.dialect.present?

    dialect_prompt = Aloo::Assistant::ARABIC_DIALECTS.dig(current_assistant.dialect, :prompt)
    return nil unless dialect_prompt

    "7. When responding in Arabic: #{dialect_prompt}"
  end
end
