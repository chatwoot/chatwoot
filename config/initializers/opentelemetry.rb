require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'base64'

Rails.application.config.after_initialize do
  otel_provider = InstallationConfig.find_by(name: 'OTEL_PROVIDER')&.value
  next unless otel_provider == 'langfuse'

  langfuse_endpoint = InstallationConfig.find_by(name: 'LANGFUSE_BASE_URL')&.value
  langfuse_public_key = InstallationConfig.find_by(name: 'LANGFUSE_PUBLIC_KEY')&.value
  langfuse_secret_key = InstallationConfig.find_by(name: 'LANGFUSE_SECRET_KEY')&.value

  if langfuse_endpoint.blank? || langfuse_public_key.blank? || langfuse_secret_key.blank?
    Rails.logger.error 'OpenTelemetry disabled (LANGFUSE_BASE_URL, LANGFUSE_PUBLIC_KEY or LANGFUSE_SECRET_KEY is missing)'
    next
  end

  langfuse_api_endpoint = "#{langfuse_endpoint}/api/public/otel"
  traces_endpoint = "#{langfuse_api_endpoint}/v1/traces"

  OpenTelemetry::SDK.configure do |c|
    c.service_name = 'chatwoot'

    exporter_config = {
      endpoint: traces_endpoint,
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{langfuse_public_key}:#{langfuse_secret_key}")}"
      }
    }

    exporter_config[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(**exporter_config)

    c.add_span_processor(
      OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
    )

    Rails.logger.info 'OpenTelemetry initialized and configured to export to Langfuse'
  end
end
