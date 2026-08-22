Searchkick.queue_name = :async_database_migration if ENV.fetch('OPENSEARCH_URL', '').present?

api_key = ENV.fetch('OPENSEARCH_API_KEY', '').presence || ENV.fetch('ELASTICSEARCH_API_KEY', '').presence
access_key_id = ENV.fetch('OPENSEARCH_AWS_ACCESS_KEY_ID', '')
secret_access_key = ENV.fetch('OPENSEARCH_AWS_SECRET_ACCESS_KEY', '')

if api_key.present?
  Searchkick.client_options = Searchkick.client_options.deep_merge(
    transport_options: {
      headers: {
        'Authorization' => "ApiKey #{api_key}"
      }
    }
  )
elsif access_key_id.present? && secret_access_key.present?
  region = ENV.fetch('OPENSEARCH_AWS_REGION', 'us-east-1')

  Searchkick.aws_credentials = {
    access_key_id: access_key_id,
    secret_access_key: secret_access_key,
    region: region
  }
end
