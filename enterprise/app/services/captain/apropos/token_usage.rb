class Captain::Apropos::TokenUsage
  def self.record(runtime, message, source:)
    return unless message.role == :assistant

    runtime.record('usage', {
                     source: source,
                     model: message.model_id,
                     input_tokens: message.input_tokens,
                     output_tokens: message.output_tokens
                   })
  end
end
