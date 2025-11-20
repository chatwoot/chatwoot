require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'base64'

if ENV['OTEL_PROVIDER'] == 'langfuse'
  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'chatwoot'

    # For EU region, set LANGFUSE_BASE_URL to https://cloud.langfuse.com
    # https://langfuse.com/integrations/native/opentelemetry
    langfuse_endpoint = ENV.fetch('LANGFUSE_BASE_URL', 'https://us.cloud.langfuse.com')
    langfuse_api_endpoint = "#{langfuse_endpoint}/api/public/otel"
    traces_endpoint = "#{langfuse_api_endpoint}/v1/traces"

    exporter_config = {
      endpoint: traces_endpoint,
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{ENV.fetch('LANGFUSE_PUBLIC_KEY', nil)}:#{ENV.fetch('LANGFUSE_SECRET_KEY', nil)}")}"
      }
    }

    exporter_config[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(**exporter_config)

    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
    )

    Rails.logger.info 'OpenTelemetry initialized and configured to export to Langfuse'
  end
else
  Rails.logger.debug 'OpenTelemetry disabled (set OTEL_PROVIDER=langfuse to enable)'
end
