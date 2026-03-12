class Captain::SummaryService < Captain::BaseTaskService
  pattr_initialize [:account!, :conversation_display_id!]

  def perform
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: conversation.to_llm_text(include_contact_details: false) }
      ]
    )
  end

  private

  def system_prompt
    "#{prompt_from_file('summary')}\n\nReply in #{account.locale_english_name}."
  end

  def event_name
    'summarize'
  end
end
