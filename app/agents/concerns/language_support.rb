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
    PROMPT
  end
end
