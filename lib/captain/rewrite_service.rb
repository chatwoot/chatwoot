class Captain::RewriteService < Captain::BaseTaskService
  pattr_initialize [:account!, :content!, :operation!, { conversation_display_id: nil }]

  def execute_task
    send(operation)
  end

  private

  def fix_spelling_grammar
    call_llm_with_prompt(prompt_from_file('fix_spelling_grammar'))
  end

  def casual
    call_llm_with_prompt(tone_rewrite_prompt('casual'))
  end

  def professional
    call_llm_with_prompt(tone_rewrite_prompt('professional'))
  end

  def friendly
    call_llm_with_prompt(tone_rewrite_prompt('friendly'))
  end

  def confident
    call_llm_with_prompt(tone_rewrite_prompt('confident'))
  end

  def straightforward
    call_llm_with_prompt(tone_rewrite_prompt('straightforward'))
  end

  def improve
    template = prompt_from_file('improve')

    system_prompt = render_liquid_template(template, {
                                             'conversation_context' => conversation.to_llm_text(include_contact_details: true),
                                             'draft_message' => content
                                           })

    call_llm_with_prompt(system_prompt, content)
  end

  def call_llm_with_prompt(system_content, user_content = content)
    make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_content },
        { role: 'user', content: user_content }
      ]
    )
  end

  def render_liquid_template(template_content, variables = {})
    Liquid::Template.parse(template_content).render(variables)
  end

  def tone_rewrite_prompt(tone)
    template = prompt_from_file('tone_rewrite')
    render_liquid_template(template, 'tone' => tone)
  end

  def event_name
    operation
  end
end
