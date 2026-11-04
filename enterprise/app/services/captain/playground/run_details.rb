class Captain::Playground::RunDetails
  RESULT_PREVIEW_LENGTH = 500
  SENSITIVE_KEY_PATTERN = /authorization|cookie|credential|password|secret|token|api.?key/i
  SENSITIVE_HEADER_PATTERN = /((?:authorization|proxy-authorization|cookie|set-cookie)\s*["']?\s*[:=]\s*)[^\r\n]+/i
  SENSITIVE_VALUE_PATTERN = /((?:password|secret|token|api[_-]?key|credential)\s*["']?\s*[:=]\s*)(?:"[^"]*"|'[^']*'|[^\s,;}]+)/i

  def initialize(configuration:)
    @configuration = configuration
    @events = []
    @started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def callbacks
    {
      on_tool_start: method(:tool_started),
      on_tool_complete: method(:tool_completed),
      on_agent_handoff: method(:agent_handed_off)
    }
  end

  def to_h(agent_name:)
    {
      handler: @configuration.handler_for(agent_name),
      events: @events,
      temporary_knowledge_attached: @configuration.knowledge_text.present?,
      duration_ms: elapsed_milliseconds
    }
  end

  private

  def tool_started(name, arguments, _context)
    @events << {
      type: 'tool',
      name: public_tool_name(name),
      status: 'running',
      arguments: sanitize(arguments)
    }
  end

  def tool_completed(name, result, _context)
    event = @events.reverse.find do |candidate|
      candidate[:type] == 'tool' && candidate[:name] == public_tool_name(name) && candidate[:status] == 'running'
    end
    event ||= { type: 'tool', name: public_tool_name(name), arguments: {} }.tap { |new_event| @events << new_event }
    event[:status] = result.to_s.start_with?('ERROR:') ? 'failed' : 'completed'
    event[:result_preview] = preview(result)
  end

  def agent_handed_off(from_name, to_name, reason, _context)
    @events << {
      type: 'handoff',
      status: 'completed',
      from: @configuration.handler_for(from_name),
      to: @configuration.handler_for(to_name),
      reason: preview(reason)
    }
  end

  def public_tool_name(name)
    name.to_s.split('--').last
  end

  def sanitize(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, item), sanitized|
        sanitized[key] = key.to_s.match?(SENSITIVE_KEY_PATTERN) ? '[REDACTED]' : sanitize(item)
      end
    when Array
      value.map { |item| sanitize(item) }
    when String
      sanitize_string(value).first(RESULT_PREVIEW_LENGTH)
    else
      value
    end
  end

  def preview(result)
    sanitize(result).to_s.first(RESULT_PREVIEW_LENGTH)
  end

  def sanitize_string(value)
    parsed = JSON.parse(value)
    return sanitize(parsed).to_json if parsed.is_a?(Hash) || parsed.is_a?(Array)

    redact_inline_credentials(value)
  rescue JSON::ParserError
    redact_inline_credentials(value)
  end

  def redact_inline_credentials(value)
    value.gsub(SENSITIVE_HEADER_PATTERN, '\\1[REDACTED]').gsub(SENSITIVE_VALUE_PATTERN, '\\1[REDACTED]')
  end

  def elapsed_milliseconds
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - @started_at) * 1000).round
  end
end
