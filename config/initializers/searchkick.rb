opensearch_url = ENV.fetch('OPENSEARCH_URL', '').presence
elasticsearch_url = ENV.fetch('ELASTICSEARCH_URL', '').presence

opensearch_api_key = ENV.fetch('OPENSEARCH_API_KEY', '').presence
elasticsearch_api_key = ENV.fetch('ELASTICSEARCH_API_KEY', '').presence
api_key = opensearch_api_key || elasticsearch_api_key
access_key_id = ENV.fetch('OPENSEARCH_AWS_ACCESS_KEY_ID', '')
secret_access_key = ENV.fetch('OPENSEARCH_AWS_SECRET_ACCESS_KEY', '')
use_elasticsearch_client = elasticsearch_url.present? || (elasticsearch_api_key.present? && opensearch_api_key.blank?)
search_url = use_elasticsearch_client ? (elasticsearch_url || opensearch_url) : opensearch_url

if search_url.present?
  Searchkick.queue_name = :async_database_migration
  Searchkick.client_type = use_elasticsearch_client ? :elasticsearch : :opensearch
  Searchkick.client_options = Searchkick.client_options.deep_merge(url: search_url) if use_elasticsearch_client
end

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

module SearchkickServerlessCompatibility
  unless const_defined?(:SERVERLESS_UNSUPPORTED_ANALYZERS, false)
    SERVERLESS_UNSUPPORTED_ANALYZERS = %i[
      searchkick_suggest_index
      searchkick_text_start_index
      searchkick_text_middle_index
      searchkick_text_end_index
      searchkick_word_start_index
      searchkick_word_middle_index
      searchkick_word_end_index
    ].freeze
  end

  unless const_defined?(:SERVERLESS_UNSUPPORTED_FILTERS, false)
    SERVERLESS_UNSUPPORTED_FILTERS = %w[
      searchkick_index_shingle
      searchkick_search_shingle
      searchkick_suggest_shingle
      searchkick_edge_ngram
      searchkick_ngram
    ].freeze
  end

  def index_options
    super.tap do |body|
      remove_serverless_unsupported_index_options(body) if elasticsearch_serverless?
    end
  end

  private

  def elasticsearch_serverless?
    return false unless Searchkick.client_type == :elasticsearch

    server_info = Searchkick.server_info
    server_info = server_info.to_h if server_info.respond_to?(:to_h)
    version = server_info['version'] || server_info[:version] || {}
    (version['build_flavor'] || version[:build_flavor]).to_s == 'serverless'
  rescue StandardError
    false
  end

  def remove_serverless_unsupported_index_options(body)
    settings = body[:settings]
    settings.delete(:number_of_shards)
    settings.delete(:number_of_replicas)

    index_settings = settings[:index] || settings['index']
    index_settings&.delete(:max_ngram_diff)
    index_settings&.delete(:max_shingle_diff)
    remove_serverless_unsupported_analysis(settings)
  end

  def remove_serverless_unsupported_analysis(settings)
    analysis = settings[:analysis] || settings['analysis']
    return if analysis.blank?

    remove_serverless_unsupported_analyzers(analysis[:analyzer] || analysis['analyzer'] || {})
    remove_serverless_unsupported_filters(analysis[:filter] || analysis['filter'] || {})
  end

  def remove_serverless_unsupported_analyzers(analyzers)
    SERVERLESS_UNSUPPORTED_ANALYZERS.each { |name| analyzers.delete(name) }
    analyzers.each_value do |config|
      remove_serverless_unsupported_filter_references(config[:filter])
      remove_serverless_unsupported_filter_references(config['filter'])
    end
  end

  def remove_serverless_unsupported_filter_references(filters)
    filters&.reject! { |filter| SERVERLESS_UNSUPPORTED_FILTERS.include?(filter) }
  end

  def remove_serverless_unsupported_filters(filters)
    SERVERLESS_UNSUPPORTED_FILTERS.each do |name|
      filters.delete(name.to_sym)
      filters.delete(name)
    end
  end
end

Searchkick::IndexOptions.prepend(SearchkickServerlessCompatibility) unless Searchkick::IndexOptions < SearchkickServerlessCompatibility
