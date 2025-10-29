class Captain::Assistant::ChangeToneService < Captain::Assistant::BaseAssistantService
  SUPPORTED_TONES = %w[professional casual straightforward confident friendly].freeze

  def initialize(text:, tone:)
    super(text: text)
    @tone = validate_tone(tone)
  end

  protected

  def agent_name
    'ToneChanger'
  end

  def build_instructions
    context = { tone: @tone }
    Captain::PromptRenderer.render('rewrite/tone', context.with_indifferent_access)
  end

  def response_schema
    {
      type: 'object',
      properties: {
        rewritten_text: {
          type: 'string',
          description: 'The rewritten text with the requested tone applied'
        },
        tone_applied: {
          type: 'string',
          description: 'The tone that was applied to the text'
        }
      },
      required: %w[rewritten_text tone_applied],
      additionalProperties: false
    }
  end

  def build_success_response(output)
    {
      success: true,
      rewritten_text: extract_field(output, 'rewritten_text'),
      tone: @tone,
      original_text: @text
    }
  end

  private

  def validate_tone(tone)
    tone_str = tone.to_s.downcase

    raise ArgumentError, "Unsupported tone: #{tone}. Supported tones: #{SUPPORTED_TONES.join(', ')}" unless SUPPORTED_TONES.include?(tone_str)

    tone_str
  end
end
