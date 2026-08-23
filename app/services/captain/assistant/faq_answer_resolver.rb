require 'agents'
require 'agents/instrumentation'

# Resolves a placeholder non-answer from the agent (e.g. "I'll check our FAQ
# database...") by deterministically running the FAQ lookup against the customer's
# question and producing a real answer from the retrieved knowledge. The main
# agent runner relies on the model to invoke the FAQ tool itself, but weaker
# models sometimes emit a promise to check instead of actually calling the tool;
# this guard guarantees an answer when the FAQ contains relevant content.
class Captain::Assistant::FaqAnswerResolver
  include Integrations::LlmInstrumentationConstants

  AGENT_NAME = 'captain_faq_answer'.freeze
  INSTRUCTIONS = 'Answer the customer question directly using only the retrieved FAQ knowledge below. ' \
                 'Do not say you will check, look up, investigate, or search anything. ' \
                 'Provide the answer now based on the provided knowledge, in the same language as the question.'.freeze

  NON_ANSWER_PATTERNS = [
    /\bI'?ll (check|look|search|investigate|find|find out|look up|take a look|get back)\b/i,
    /\bI will (check|look|search|investigate|find|find out|look up|get back)\b/i,
    /\blet me (check|look|search|investigate|find|find out|pull up)\b/i,
    /\bI'?ll look into\b/i,
    /\b(checking|looking|searching|check|look) (our |the )?(faq|database|knowledge|records|system|knowledge base|documents)\b/i,
    /\b(searching|looking) (for )?(information|the answer|that|this)\b/i,
    /\b(one moment|hang on|let me see|let me check on that)\b/i
  ].freeze

  def initialize(assistant:, attribute_provider:)
    @assistant = assistant
    @attribute_provider = attribute_provider
  end

  # True when the model replied with a promise to investigate rather than an
  # actual answer. The existing prompt rule already forbids this, so any such
  # response is a prompt/model failure that should be resolved deterministically.
  def placeholder_non_answer?(response_text)
    NON_ANSWER_PATTERNS.any? { |pattern| response_text.match?(pattern) }
  end

  # Runs the FAQ lookup for the customer's question and, when relevant content is
  # found, replaces the run result output with a focused answer generated from it.
  # Returns the original run result unchanged when the FAQ has nothing usable.
  def resolve(user_question, run_result)
    faq_lookup_state = lookup_state
    faq_content = run_faq_lookup(user_question, faq_lookup_state)
    return run_result if faq_content.blank?

    answer_run_result = run_focused_answer(user_question, faq_content, run_result)
    return run_result if answer_run_result.failed?

    merge_faq_sources_into_run_state(run_result, faq_lookup_state)
    replace_final_assistant_output(run_result, answer_run_result.output)
    run_result.output = answer_run_result.output
    run_result
  end

  private

  def lookup_state
    {
      :cw_metadata => {},
      Captain::Assistant::CITATION_SOURCES_STATE_KEY => {}
    }
  end

  # The FAQ lookup writes the sources it retrieved into the tool context state.
  # That state is a throwaway here, so merge it back into the run's context state
  # afterwards; otherwise the session/analytics records would show no FAQ usage
  # even though the answer was built from the knowledge base.
  def merge_faq_sources_into_run_state(run_result, lookup_state)
    run_state = run_result.context[:state] ||= {}

    run_state[:cw_metadata] ||= {}
    %i[faq_ids document_ids used_faq_ids].each do |key|
      run_state[:cw_metadata][key] = Array(run_state[:cw_metadata][key]) | Array(lookup_state[:cw_metadata][key])
    end

    citation_key = Captain::Assistant::CITATION_SOURCES_STATE_KEY
    run_state[citation_key] = (run_state[citation_key] || {}).merge(lookup_state[citation_key] || {})
  end

  def run_faq_lookup(user_question, faq_lookup_state)
    tool_context = Struct.new(:state).new(faq_lookup_state)
    Captain::Tools::FaqLookupTool.new(@assistant).perform(tool_context, query: user_question)
  end

  def run_focused_answer(user_question, faq_content, run_result)
    answer_prompt = build_answer_prompt(user_question, faq_content)
    answer_context = {
      session_id: run_result.context[:session_id],
      state: run_result.context[:state],
      captain_v2_trace_input: answer_prompt
    }
    runner.run(answer_prompt, context: answer_context, max_turns: 1)
  end

  def build_answer_prompt(user_question, faq_content)
    "Customer question: #{user_question}\n\nRetrieved FAQ knowledge:\n#{faq_content}"
  end

  def runner
    @runner ||= begin
      agent = Agents::Agent.new(
        name: AGENT_NAME,
        instructions: INSTRUCTIONS,
        model: @assistant.agent_model,
        provider: Llm::Config.chat_provider(@assistant.agent_model),
        assume_model_exists: Llm::Config.assume_chat_model_exists?,
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
      trace_name: 'llm.captain_v2.faq_answer',
      span_attributes: {
        ATTR_LANGFUSE_TAGS => %w[captain_v2 faq_answer_resolver].to_json,
        format(ATTR_LANGFUSE_METADATA, 'credit_used') => 'true'
      },
      attribute_provider: @attribute_provider
    )
  end

  def replace_final_assistant_output(run_result, output)
    replace_in_history(run_result.context[:conversation_history], output)
    replace_in_history(run_result.messages, output)
  end

  def replace_in_history(messages, output)
    index = Array(messages).rindex { |message| message[:role].to_s == 'assistant' }
    return unless index

    messages[index] = messages[index].merge(content: output)
  end
end
