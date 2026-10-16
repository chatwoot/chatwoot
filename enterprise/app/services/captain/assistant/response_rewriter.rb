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

  def rewrite(run_result, response_parts:, response_text_limit:)
    rewrite_prompt = build_rewrite_prompt(response_parts, response_text_limit)
    rewrite_context = {
      session_id: run_result.context[:session_id],
      state: run_result.context[:state],
      captain_v2_trace_input: rewrite_prompt
    }
    rewrite_run_result = runner.run(rewrite_prompt, context: rewrite_context, max_turns: 1)
    raise rewrite_run_result.error || 'Captain response rewrite failed' if rewrite_run_result.failed?

    rewritten_model_output = rewritten_response_with_original_citations(rewrite_run_result.output, response_parts)
    replace_final_assistant_output(run_result.context[:conversation_history], rewritten_model_output)
    replace_final_assistant_output(run_result.messages, rewritten_model_output)
    run_result.output = rewritten_model_output
    run_result
  end

  private

  def build_rewrite_prompt(response_parts, response_text_limit)
    response_text = response_parts.plain_text

    "The response text below is #{response_text.length} characters, but it must be at most #{response_text_limit} characters " \
      'so the complete customer message fits this channel. ' \
      'Shorten the text in each response part so the joined customer message fits the limit. ' \
      'Keep the same number and order of response parts. Change only each text field. ' \
      'Preserve names, numbers, dates, links, warnings, and completed actions. Keep Markdown valid within each text field. Do not add facts. ' \
      "Return the complete structured response.\n\nResponse parts:\n#{response_parts.to_a.to_json}"
  end

  def rewritten_response_with_original_citations(rewritten_model_output, original_response_parts)
    rewritten_model_output = rewritten_model_output.with_indifferent_access
    rewritten_response_parts = Captain::Assistant::ResponseParts.from_response(rewritten_model_output)
    original_parts = original_response_parts.to_a
    rewritten_parts = rewritten_response_parts.to_a
    raise 'Captain response rewrite changed the number of response parts' unless rewritten_parts.size == original_parts.size

    original_citation_indexes = original_parts.pluck('citation_indexes')
    rewritten_citation_indexes = rewritten_parts.pluck('citation_indexes')
    if @assistant.citations_enabled? && rewritten_citation_indexes != original_citation_indexes
      raise 'Captain response rewrite changed the response part citation order'
    end

    rewritten_model_output['response_parts'] = rewritten_parts.zip(original_parts).map do |rewritten_part, original_part|
      rewritten_part.merge('citation_indexes' => original_part['citation_indexes'])
    end
    rewritten_model_output
  end

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
