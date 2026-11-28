# The messages that open every Copilot turn: the instructions with the tools and the account, plus the turn context that
# follows the agent's message. Included by Captain::Copilot::TurnService, which sets the run, account, assistant, user,
# tools and viewed conversation.
module Captain::Copilot::TurnPrompt
  private

  # The workflow instructions are the whole prompt. The old Copilot prompt in ChatService was written for a helper
  # without tools, and its rules to ask before acting, keep answers short and cite sources worked against them. The
  # instructions explain Chatwoot's fields, because without them the model treats status and priority as content. Chatwoot
  # support can help only with Cloud accounts; a self-hosted account's problems go to the people who run the installation.
  def system_message
    instructions = Captain::PromptRenderer.render('copilot_workflows', product_name: @assistant.config['product_name'],
                                                                       conversations_per_turn: CopilotRun::CONVERSATIONS_PER_TURN,
                                                                       chatwoot_cloud: ChatwootApp.chatwoot_cloud?,
                                                                       chatwoot_docs: @tools.any? { |tool| tool.name == 'search_chatwoot_docs' },
                                                                       user_name: @user.name, user_id: @user.id)
    tools = @tools.map { |tool| "- #{tool.name}: #{tool.description}" }.join("\n")
    { role: 'system', content: "#{instructions}\n\nTools:\n#{tools}" }
  end

  def account_message
    { role: 'system', content: "Account ID #{@account.id}. Answer in the language of the agent's latest message. Only when that message " \
                               "has no clear language, answer in #{@account.locale_english_name}." }
  end

  # Values that change from turn to turn. They follow the agent's message instead of sitting in the instructions, and
  # are saved with the turn, so later turns replay them in the same place and the prompt prefix stays cacheable. The
  # current time is the turn's own, so a retried or resumed turn reads the same dates. It is in the reporting time zone,
  # where reports cut their days, so today is the account's date.
  def turn_context_message
    lines = ["Current time: #{@run.created_at.in_time_zone(@account.report_time_zone).iso8601}, in the account reporting time zone."]
    if @conversation.present?
      lines << "The agent is viewing the conversation with Conversation ID #{@conversation_id} and Contact ID #{@conversation.contact_id}."
    end
    { role: :user, content: "Context for this turn, from Chatwoot rather than the agent:\n#{lines.join("\n")}" }
  end
end
