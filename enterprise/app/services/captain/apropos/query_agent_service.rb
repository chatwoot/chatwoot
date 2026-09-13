class Captain::Apropos::QueryAgentService < Captain::BaseTaskService
  pattr_initialize [:account!, :runtime!, :instruction!]

  def perform
    Captain::Apropos::Access.check!(account, runtime.user)
    return { error: I18n.t('captain.api_key_missing') } unless api_key_configured?

    tool = Captain::Apropos::QueryTool.new(runtime)
    response = run_query_agent(tool)
    return { message: tool.result } if tool.result

    { error: "No WootQL query was executed. #{response.content.to_s.truncate(1_000)}" }
  end

  private

  def run_query_agent(tool)
    model = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL
    Llm::Config.with_api_key(api_key, api_base: api_base) do |context|
      chat = context.chat(model: model).with_temperature(0).with_instructions(system_prompt).with_tool(tool, calls: :one)
      chat.singleton_class.prepend(Captain::Apropos::RequestBudget)
      chat.singleton_class.prepend(Captain::Apropos::QueryRequestBudget)
      chat.after_message do |message|
        Captain::Apropos::TokenUsage.record(runtime, message, source: 'query')
        record_generation(chat, message, model)
      end
      chat.ask(JSON.generate({ retrieval_request: instruction, run_context: runtime.run_context }))
    end
  end

  def system_prompt
    Captain::Apropos::Prompt.render(:query, 'wootql_reference' => JSON.generate(Captain::Apropos::Catalog::WOOTQL),
                                            'resource_schema' => JSON.generate(runtime.query_schema))
  end

  def event_name = 'apropos_query'
end
