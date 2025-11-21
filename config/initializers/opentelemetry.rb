# require 'opentelemetry/sdk'
# require 'opentelemetry/exporter/otlp'
# require 'base64'

# Rails.application.config.after_initialize do
#   otel_provider = InstallationConfig.find_by(name: 'OTEL_PROVIDER')&.value
#   if otel_provider == 'langfuse'
#     OpenTelemetry::SDK.configure do |c|
#       c.service_name = 'chatwoot'

#       langfuse_endpoint = InstallationConfig.find_by(name: 'LANGFUSE_BASE_URL')&.value
#       langfuse_api_endpoint = "#{langfuse_endpoint}/api/public/otel"
#       langfuse_public_key = InstallationConfig.find_by(name: 'LANGFUSE_PUBLIC_KEY')&.value
#       langfuse_secret_key = InstallationConfig.find_by(name: 'LANGFUSE_SECRET_KEY')&.value
#       traces_endpoint = "#{langfuse_api_endpoint}/v1/traces"

#       exporter_config = {
#         endpoint: traces_endpoint,
#         headers: {
#           'Authorization' => "Basic #{Base64.strict_encode64("#{langfuse_public_key}:#{langfuse_secret_key}")}"
#         }
#       }

#       exporter_config[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

#       exporter = OpenTelemetry::Exporter::OTLP::Exporter.new(**exporter_config)

#       c.add_span_processor(
#         OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(exporter)
#       )

#       Rails.logger.info 'OpenTelemetry initialized and configured to export to Langfuse'
#     end
#   else
#     Rails.logger.debug 'OpenTelemetry disabled (set OTEL_PROVIDER=langfuse to enable)'
#   end
# rescue StandardError => e
#   Rails.logger.error "Failed to configure OpenTelemetry: #{e.message}"
# end
