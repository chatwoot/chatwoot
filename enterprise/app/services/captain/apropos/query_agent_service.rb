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
    runtime.instrument('llm.apropos.query', { 'query.instruction' => instruction }, observation_type: 'agent') do
      Llm::Config.with_api_key(api_key, api_base: api_base) do |context|
        chat = build_query_chat(context, tool, model)
        chat.ask(JSON.generate({ retrieval_request: instruction, run_context: runtime.run_context }))
      end
    end
  end

  def build_query_chat(context, tool, model)
    chat = context.chat(model: model).with_temperature(0).with_instructions(system_prompt).with_tool(tool, calls: :one)
    chat.singleton_class.prepend(Captain::Apropos::RequestBudget)
    chat.singleton_class.prepend(Captain::Apropos::QueryRequestBudget)
    chat.after_message do |message|
      Captain::Apropos::TokenUsage.record(runtime, message, source: 'query')
      Captain::Apropos::Instrumentation.record_generation(runtime: runtime, chat: chat, message: message, model: model, role: 'query')
    end
    chat
  end

  def system_prompt
    Captain::Apropos::Prompt.render(:query, 'wootql_reference' => JSON.generate(Captain::Apropos::Catalog::WOOTQL),
                                            'resource_schema' => JSON.generate(runtime.query_schema))
  end

  def event_name = 'apropos_query'
end
