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
    /\bI'?ll (check|look|search|investigate|find|find out|look up|take a look)\b/i,
    /\bI will (check|look|search|investigate|find|find out|look up)\b/i,
    /\blet me (check|look|search|investigate|find|find out)\b/i,
    /\bI'?ll look into\b/i,
    /\b(checking|looking|searching) (our|the) (faq|database|knowledge|records|system)\b/i
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
    faq_content = run_faq_lookup(user_question)
    return run_result if faq_content.blank?

    answer_run_result = run_focused_answer(user_question, faq_content, run_result)
    return run_result if answer_run_result.failed?

    replace_final_assistant_output(run_result, answer_run_result.output)
    run_result.output = answer_run_result.output
    run_result
  end

  private

  def run_faq_lookup(user_question)
    state = {
      cw_metadata: {},
      Captain::Assistant::CITATION_SOURCES_STATE_KEY => {}
    }
    tool_context = Struct.new(:state).new(state)
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