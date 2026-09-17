# Attach only to Apropos chat instances, not to RubyLLM globally.
# Chat#complete is also called recursively after tool results in RubyLLM 1.15.
# https://github.com/crmne/ruby_llm/blob/v1.15.0/lib/ruby_llm/chat.rb
module Captain::Apropos::RequestBudget
  # TODO: Checkpoint completed phases and compact obsolete runner history while preserving the objective, bindings, coverage, findings, and
  # receipts. Workspace references bound the size of individual tool results, but the agent runner still retains every tool call and response in its
  # message history. Discovery output, failed attempts, and execution feedback therefore accumulate across a repair-heavy turn. A run can
  # finish its substantive work and then exceed REQUEST_BYTES when requesting the final response. Increasing the byte limit only postpones the
  # same failure mode.
  def complete(&)
    serialized_messages = messages.map do |message|
      message.to_h.merge(tool_calls: message.tool_calls&.transform_values(&:to_h))
    end
    payload = { messages: serialized_messages, schema: schema, tools: tools.transform_values(&:parameters) }
    if JSON.generate(payload).bytesize > Captain::Apropos::ContextLimits::REQUEST_BYTES
      raise Captain::Apropos::Error, 'Apropos context budget reached before sending the next model request. ' \
                                     'Workspace bindings and completed action receipts are preserved. Continue in a new turn using compact findings.'
    end

    super
  end
end
