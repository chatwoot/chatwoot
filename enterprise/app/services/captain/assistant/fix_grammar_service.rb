class Captain::Assistant::FixGrammarService < Captain::Assistant::BaseRewriteService
  protected

  def agent_name
    'GrammarFixer'
  end

  def build_instructions
    Captain::PromptRenderer.render('rewrite/grammar', {})
  end

  def response_schema
    {
      type: 'object',
      properties: {
        corrected_text: {
          type: 'string',
          description: 'The text with corrected grammar, spelling, and punctuation'
        },
        corrections_made: {
          type: 'array',
          description: 'List of corrections that were made',
          items: {
            type: 'string'
          }
        }
      },
      required: ['corrected_text'],
      additionalProperties: false
    }
  end

  def build_success_response(output)
    {
      success: true,
      corrected_text: extract_field(output, 'corrected_text'),
      corrections_made: extract_corrections(output),
      original_text: @text
    }
  end

  private

  def extract_corrections(output)
    return [] unless output.is_a?(Hash)

    output[:corrections_made] || output['corrections_made'] || []
  end
end
