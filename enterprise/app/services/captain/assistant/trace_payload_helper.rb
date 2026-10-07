module Captain::Assistant::TracePayloadHelper
  private

  def enrich_context_with_trace_payload!(context, message_history, message_to_process)
    context[:captain_v2_trace_input] = serialize_trace_messages(message_history)
    context[:captain_v2_trace_current_input] = serialize_trace_content(message_to_process)
  end

  def serialize_trace_messages(message_history)
    message_history.map do |message|
      {
        role: message[:role].to_s,
        content: trace_content_payload(message[:content])
      }
    end.to_json
  end

  def serialize_trace_content(content)
    payload = trace_content_payload(content)
    return '' if payload.blank?

    payload.is_a?(String) ? payload : payload.to_json
  end

  def trace_content_payload(content)
    case content
    when Array, Hash
      content
    when NilClass
      ''
    else
      content.to_s
    end
  end
end
