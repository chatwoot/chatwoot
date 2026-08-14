require 'agents'

module Captain::Routines::AgentTask
  private

  def run_agent(input:, **options)
    return { error: I18n.t('captain.api_key_missing'), error_code: 401 } unless api_key_configured?

    # Agents are immutable; all request-specific state is supplied through runner context.
    # Source: https://github.com/chatwoot/ai-agents#context-management--persistence
    runner = Agents::Runner.with_agents(build_agent(options))
    result = runner.run(input, context: options.fetch(:context, {}), max_turns: options.fetch(:max_turns, 10))
    return agent_error(result.error) if result.error

    agent_response(result)
  rescue StandardError => e
    agent_error(e)
  end

  def build_agent(options)
    Agents::Agent.new(
      name: options.fetch(:name),
      instructions: options.fetch(:instructions),
      model: agent_model,
      tools: options.fetch(:tools, []),
      temperature: 0,
      response_schema: options.fetch(:schema)
    )
  end

  def agent_response(result)
    {
      message: result.output,
      usage: {
        'prompt_tokens' => result.usage.input_tokens,
        'completion_tokens' => result.usage.output_tokens,
        'total_tokens' => result.usage.total_tokens
      },
      agent_context: result.context
    }
  end

  def agent_model
    InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_MODEL')&.value.presence || Captain::BaseTaskService::GPT_MODEL
  end

  def agent_error(error)
    message = error.respond_to?(:message) ? error.message : error.to_s
    { error: message, error_code: 422 }
  end
end
