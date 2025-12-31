# frozen_string_literal: true

module Aloo
  class PersonalityBuilder
    TONE_PROMPTS = {
      'professional' => 'Maintain a professional and business-like tone. Be courteous and efficient.',
      'friendly' => 'Be warm, approachable, and conversational. Use a friendly tone that makes customers feel comfortable.',
      'casual' => "Be relaxed and informal. Use casual language like you're chatting with a friend.",
      'formal' => 'Use formal language and proper etiquette. Be respectful and dignified in all responses.'
    }.freeze

    FORMALITY_PROMPTS = {
      'high' => 'Use formal greetings, proper titles, and avoid contractions or slang.',
      'medium' => 'Balance formal and informal language appropriately based on context.',
      'low' => 'Feel free to use contractions, casual expressions, and relaxed language.'
    }.freeze

    EMPATHY_PROMPTS = {
      'high' => 'Show strong empathy. Acknowledge customer emotions and frustrations explicitly. ' \
                'Use phrases like "I understand how frustrating this must be" or "I can see why you\'re concerned."',
      'medium' => 'Show appropriate empathy when customers express frustration or concern.',
      'low' => 'Focus on solutions rather than emotional acknowledgment. Be efficient and direct.'
    }.freeze

    VERBOSITY_PROMPTS = {
      'concise' => 'Keep responses brief and to the point. Avoid unnecessary details.',
      'balanced' => 'Provide enough detail to be helpful without being verbose.',
      'detailed' => 'Provide comprehensive, detailed responses with full explanations.'
    }.freeze

    EMOJI_PROMPTS = {
      'none' => 'Do not use any emojis in your responses.',
      'minimal' => 'Use emojis sparingly, only when they add warmth (like a greeting or thank you).',
      'moderate' => 'Feel free to use emojis to add personality and warmth to your responses.'
    }.freeze

    def initialize(assistant)
      @assistant = assistant
    end

    def build
      sections = []

      sections << '## Communication Style'
      sections << TONE_PROMPTS[@assistant.tone]
      sections << FORMALITY_PROMPTS[@assistant.formality]
      sections << EMPATHY_PROMPTS[@assistant.empathy_level]
      sections << VERBOSITY_PROMPTS[@assistant.verbosity]
      sections << EMOJI_PROMPTS[@assistant.emoji_usage]

      if @assistant.personality_description.present?
        sections << "\n## Additional Personality Traits"
        sections << @assistant.personality_description
      end

      if @assistant.language_instruction.present?
        sections << "\n## Language"
        sections << @assistant.language_instruction
      end

      if @assistant.greeting_style == 'custom' && @assistant.custom_greeting.present?
        sections << "\n## Greeting"
        sections << "When starting a conversation, use this greeting: \"#{@assistant.custom_greeting}\""
      end

      sections.compact.join("\n")
    end
  end
end
