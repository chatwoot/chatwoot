# The messages that open every Copilot turn: the instructions with the tools, the account, and the conversation the
# agent is viewing. Included by Captain::Copilot::TurnService, which sets the run, account, assistant, user, tools and
# viewed conversation.
module Captain::Copilot::TurnPrompt
  private

  # The workflow instructions are the whole prompt. The old Copilot prompt in ChatService was written for a helper
  # without tools, and its rules to ask before acting, keep answers short and cite sources worked against them. The
  # instructions explain Chatwoot's fields, because without them the model treats status and priority as content. The
  # current time is the turn's own, so a retried or resumed turn reads the same dates. It is in the reporting time zone,
  # where reports cut their days, so today is the account's date. Chatwoot support can help only with Cloud accounts; a
  # self-hosted account's problems go to the people who run the installation.
  def system_message
    instructions = Captain::PromptRenderer.render('copilot_workflows', product_name: @assistant.config['product_name'],
                                                                       conversations_per_turn: CopilotRun::CONVERSATIONS_PER_TURN,
                                                                       chatwoot_cloud: ChatwootApp.chatwoot_cloud?,
                                                                       user_name: @user.name, user_id: @user.id,
                                                                       current_time: @run.created_at.in_time_zone(@account.report_time_zone).iso8601)
    tools = @tools.map { |tool| "- #{tool.name}: #{tool.description}" }.join("\n")
    { role: 'system', content: "#{instructions}\n\nTools:\n#{tools}" }
  end

  def account_message
    { role: 'system', content: "Account ID #{@account.id}. Answer in the language of the agent's latest message. Only when that message " \
                               "has no clear language, answer in #{@account.locale_english_name}." }
  end

  def viewed_conversation_message
    return if @conversation.blank?

    { role: 'system', content: "You are currently viewing the conversation with the following details:\n" \
                               "Conversation ID: #{@conversation_id}\nContact ID: #{@conversation.contact_id}" }
  end
end
