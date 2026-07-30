require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::ResponseRewriter
  include Integrations::LlmInstrumentationConstants

  AGENT_NAME = 'captain_response_rewriter'.freeze
  INSTRUCTIONS = 'Shorten customer support responses without changing their meaning or adding information.'.freeze

  def initialize(assistant:, attribute_provider:)
    @assistant = assistant
    @attribute_provider = attribute_provider
  end

  def rewrite(result, response:, limit:)
    prompt = "The response below is #{response.length} characters, but this channel allows a maximum of #{limit}. " \
             'Shorten it while preserving names, numbers, dates, links, warnings, and completed actions. ' \
             "Do not add facts.\n\nResponse:\n#{response}"
    context = {
      session_id: result.context[:session_id],
      state: result.context[:state],
      captain_v2_trace_input: prompt
    }
    rewritten_result = runner.run(prompt, context: context, max_turns: 1)
    raise rewritten_result.error || 'Captain response rewrite failed' if rewritten_result.failed?

    replace_final_assistant_output(result.context[:conversation_history], rewritten_result.output)
    replace_final_assistant_output(result.messages, rewritten_result.output)
    result.output = rewritten_result.output
    result
  end

  private

  def runner
    @runner ||= begin
      agent = Agents::Agent.new(
        name: AGENT_NAME,
        instructions: INSTRUCTIONS,
        model: @assistant.agent_model,
        temperature: 0,
        response_schema: Captain::ResponseSchema
      )
      Agents::Runner.with_agents(agent).tap { |runner| install_instrumentation(runner) }
    end
  end

  def install_instrumentation(runner)
    return unless ChatwootApp.otel_enabled?

    Agents::Instrumentation.install(
      runner,
      tracer: OpentelemetryConfig.tracer,
      trace_name: 'llm.captain_v2.rewrite',
      span_attributes: {
        ATTR_LANGFUSE_TAGS => %w[captain_v2 channel_limit_rewrite].to_json,
        format(ATTR_LANGFUSE_METADATA, 'credit_used') => 'false'
      },
      attribute_provider: @attribute_provider
    )
  end

  def replace_final_assistant_output(messages, output)
    index = Array(messages).rindex { |message| message[:role].to_s == 'assistant' }
    return unless index

    messages[index] = messages[index].merge(content: output)
  end
end
