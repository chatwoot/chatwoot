require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'base64'

# Only configure OpenTelemetry if explicitly enabled
if ENV['OTEL_ENABLED'] == 'true'
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'chatwoot'

    # Add OTLP exporter for Langfuse
    # Langfuse expects Basic Auth: base64(public_key:secret_key)

    # default to US region will need to be changed when we have EU region available
    langfuse_endpoint = ENV.fetch('LANGFUSE_BASE_URL', 'https://us.cloud.langfuse.com')
    langfuse_api_endpoint = "#{langfuse_endpoint}/api/public/otel"
    # When endpoint is passed as a parameter, the full path including /v1/traces must be provided
    traces_endpoint = "#{langfuse_api_endpoint}/v1/traces"

    exporter_config = {
      endpoint: traces_endpoint,
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{ENV.fetch('LANGFUSE_PUBLIC_KEY', nil)}:#{ENV.fetch('LANGFUSE_SECRET_KEY', nil)}")}"
      }
    }

    # Only disable SSL verification in non-production environments
    # Production should use proper SSL verification for security
    exporter_config[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(**exporter_config)

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
