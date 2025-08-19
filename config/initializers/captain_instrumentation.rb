require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'ChatwootAppCaptain'
end

CaptainTracer = OpenTelemetry.tracer_provider.tracer('CaptainTracer')
