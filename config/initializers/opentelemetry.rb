require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

# Only configure OpenTelemetry if explicitly enabled
if ENV['OTEL_ENABLED'] == 'true'
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'chatwoot'

    # Add OTLP exporter for Langfuse
    # Langfuse expects Basic Auth: base64(public_key:secret_key)
    exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(
      endpoint: ENV.fetch('OTEL_EXPORTER_OTLP_ENDPOINT', 'https://cloud.langfuse.com/api/public/otel/v1/traces'),
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{ENV['LANGFUSE_PUBLIC_KEY']}:#{ENV['LANGFUSE_SECRET_KEY']}")}"
      },
      # Disable SSL verification for development (fix certificate issues)
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
    )

    # Use BatchSpanProcessor for better performance
    # Batches spans and exports asynchronously (default: every 5s or 2048 spans)
    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
    )

    Rails.logger.info 'OpenTelemetry initialized and configured to export to Langfuse'
  end
else
  Rails.logger.debug 'OpenTelemetry disabled (set OTEL_ENABLED=true to enable)'
end
