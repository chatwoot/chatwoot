# frozen_string_literal: true

# Provides personality and greeting logic for conversation agents
module PersonalitySupport
  extend ActiveSupport::Concern

  private

  def personality_section
    return nil unless current_assistant

    personality = Aloo::PersonalityBuilder.new(current_assistant).build
    greeting = greeting_instructions

    parts = []
    parts << section_header('COMMUNICATION STYLE')
    parts << ''
    parts << personality
    parts << greeting if greeting
    parts.compact.join("\n")
  end

  def greeting_instructions
    return nil unless current_assistant

    if first_message?
      greeting_prompt_for_first_message
    else
      'Do not greet the customer - the conversation has already started. Continue naturally from the conversation history.'
    end
  end

  def greeting_prompt_for_first_message
    case current_assistant.greeting_style
    when 'warm'
      'Start with a warm, friendly greeting to welcome the customer.'
    when 'direct'
      "Skip any greeting and address the customer's needs directly."
    when 'custom'
      if current_assistant.custom_greeting.present?
        "Start by saying: \"#{current_assistant.custom_greeting}\""
      else
        'Start with a brief greeting.'
      end
    else
      'Start with a brief greeting.'
    end
  end
end
