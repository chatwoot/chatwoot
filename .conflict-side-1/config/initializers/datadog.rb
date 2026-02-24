if ENV['DD_TRACE_AGENT_URL'].present?
  Datadog.configure do |c|
    # Instrumentation
    c.tracing.instrument :rails
  end
end
