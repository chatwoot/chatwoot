class Captain::SummaryService < Captain::BaseEditorService
  def summarize_message
    make_api_call(summarize_body)
  end

  private

  def summarize_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('summary') },
        { role: 'user', content: conversation.to_llm_text(include_contact_details: false) }
      ]
    }
  end
end
