require 'agents'

class Captain::Apropos::AgentService < Captain::BaseTaskService
  pattr_initialize [:account!, :runtime!, :instruction!, { input: nil, result_schema: nil, tools_enabled: true, history: [] }]

  def perform
    Captain::Apropos::Access.check!(account, runtime.user)
    return { error: I18n.t('captain.api_key_missing') } unless api_key_configured?

    schema = Captain::Apropos::ResultSchema.build(result_schema) if result_schema
    agent = build_agent(schema)
    # SDK context carries execution state without mutable state on tool instances.
    # Source: https://github.com/chatwoot/ai-agents#context-management--persistence
    result = run_agent(agent)
    return { error: result.error.to_s } if result.error

    { message: validate_result(result.output, schema) }
  end

  private

  def run_agent(agent)
    context = { apropos: runtime, conversation_history: runtime.model_history(history) }
    runner = Agents::Runner.with_agents(agent)
    runner.on_chat_created do |chat, *_|
      chat.singleton_class.prepend(Captain::Apropos::RequestBudget)
      chat.after_message { |message| Captain::Apropos::TokenUsage.record(runtime, message, source: tools_enabled ? 'agent' : 'reason') }
    end
    runner.run(
      JSON.generate({ task: instruction, input: runtime.model_input(input, tools: tools_enabled), run_context: runtime.run_context }),
      context: context, max_turns: 20
    )
  end

  def build_agent(schema)
    Agents::Agent.new(
      name: 'Apropos', instructions: tools_enabled ? system_prompt : reasoning_prompt, temperature: 0,
      model: InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || GPT_MODEL,
      response_schema: schema, tools: tools_enabled ? tool_instances : []
    )
  end

  def validate_result(value, schema)
    return value unless schema

    if JSON.generate(value).bytesize > Captain::Apropos::ResultSchema::MAX_RESULT_BYTES
      raise Captain::Apropos::Error, 'Agent result exceeds 64000 bytes; request smaller findings'
    end

    value = JSON.parse(value) if value.is_a?(String)
    errors = JSONSchemer.schema(schema).validate(value).take(5)
    reject_result(value, errors.map { |error| JSONSchemer::Errors.pretty(error) }.join('; ')) if errors.any?

    value
  rescue JSON::ParserError
    reject_result(value, 'Expected a valid JSON object')
  end

  def reject_result(value, details)
    reference = runtime.store(value)
    raise Captain::Apropos::Error, "Result contract failed: #{details}. Invalid output saved at #{reference}; repair only this reasoning step."
  end

  def reasoning_prompt
    Captain::Apropos::Prompt.render(:reason)
  end

  def tool_instances
    [Captain::Apropos::Tools::Apropos.new, Captain::Apropos::Tools::Describe.new, Captain::Apropos::Tools::Execute.new]
  end

  def system_prompt
    Captain::Apropos::Prompt.render(:coordinator)
  end

  def event_name = 'apropos'
end
