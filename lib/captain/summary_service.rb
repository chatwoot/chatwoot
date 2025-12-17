class Captain::SummaryService < Captain::BaseEditorService
  def summarize_message
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: prompt_from_file('summary') },
        { role: 'user', content: conversation.to_llm_text(include_contact_details: false) }
      ]
    )
  end
end
