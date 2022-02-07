if ENV['DD_TRACE_AGENT_URL']
  Datadog.configure do |c|
    # This will activate auto-instrumentation for Rails
    c.use :rails
  end
end
