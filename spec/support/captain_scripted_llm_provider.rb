# frozen_string_literal: true

# Stands in for a RubyLLM provider so specs can exercise the real
# Agents::Runner + RubyLLM::Chat tool loop without any HTTP calls.
#
# RubyLLM::Chat#handle_tool_calls recurses into #complete after every tool
# result, so a provider that keeps asking for tool calls reproduces the runaway
# loop reported in production and proves that Captain's run guards stop it.
class CaptainScriptedLlmProvider
  # Keeps a regression from hanging the suite: a broken guard fails here instead
  # of looping like the production incident did.
  MAX_COMPLETIONS = 100

  attr_reader :completions

  def initialize(tool_name:, arguments: nil, tool_calls_before_answer: nil, final_content: 'Here is your answer')
    @tool_name = tool_name
    @arguments = arguments || ->(index) { { 'query' => "question #{index}" } }
    @tool_calls_before_answer = tool_calls_before_answer
    @final_content = final_content
    @completions = 0
  end

  def connection = nil

  def complete(*_args, **_kwargs)
    @completions += 1
    raise "Tool loop was not stopped after #{MAX_COMPLETIONS} completions" if @completions > MAX_COMPLETIONS
    return RubyLLM::Message.new(role: :assistant, content: @final_content) if answer_now?

    tool_call = RubyLLM::ToolCall.new(id: "call_#{@completions}", name: @tool_name, arguments: @arguments.call(@completions))
    RubyLLM::Message.new(role: :assistant, content: '', tool_calls: { tool_call.id => tool_call })
  end

  private

  def answer_now?
    @tool_calls_before_answer.present? && @completions > @tool_calls_before_answer
  end
end
