# frozen_string_literal: true

# Stands in for a RubyLLM provider so specs can exercise the real
# Agents::Runner + RubyLLM::Chat tool loop without any HTTP calls.
#
# Each completion asks for tool_calls_per_response tool calls until
# tool_calls_before_answer completions have passed, which reproduces both the
# runaway loop reported in production and models that fan out many tool calls
# in a single response.
class CaptainScriptedLlmProvider
  # Keeps a regression from hanging the suite: a broken guard fails here instead
  # of looping like the production incident did.
  MAX_COMPLETIONS = 100

  attr_reader :completions

  def initialize(tool_name:, arguments: nil, tool_calls_per_response: 1, tool_calls_before_answer: nil, final_content: 'Here is your answer')
    @tool_name = tool_name
    @arguments = arguments || ->(index) { { 'query' => "question #{index}" } }
    @tool_calls_per_response = tool_calls_per_response
    @tool_calls_before_answer = tool_calls_before_answer
    @final_content = final_content
    @completions = 0
    @tool_calls = 0
  end

  def connection = nil
  def slug = 'captain_scripted'
  def name = self.class.name
  def preprocess_message(message, **) = message

  def complete(*_args, **_kwargs)
    @completions += 1
    raise "Tool loop was not stopped after #{MAX_COMPLETIONS} completions" if @completions > MAX_COMPLETIONS
    return RubyLLM::Message.new(role: :assistant, content: @final_content) if answer_now?

    RubyLLM::Message.new(role: :assistant, content: '', tool_calls: Array.new(@tool_calls_per_response) { next_tool_call }.index_by(&:id))
  end

  private

  def next_tool_call
    @tool_calls += 1
    RubyLLM::ToolCall.new(id: "call_#{@tool_calls}", name: @tool_name, arguments: @arguments.call(@tool_calls))
  end

  def answer_now?
    @tool_calls_before_answer.present? && @completions > @tool_calls_before_answer
  end
end
