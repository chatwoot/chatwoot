require 'rails_helper'

RSpec.describe Searchkick do
  let(:initializer_path) { Rails.root.join('config/initializers/searchkick.rb') }

  around do |example|
    original_client_options = described_class.client_options.deep_dup
    original_queue_name = described_class.queue_name
    original_aws_credentials = described_class.aws_credentials
    original_client = described_class.instance_variable_get(:@client)
    original_client_type = described_class.client_type

    example.run
  ensure
    described_class.client_options = original_client_options
    described_class.queue_name = original_queue_name
    described_class.client_type = original_client_type
    described_class.instance_variable_set(:@aws_credentials, original_aws_credentials)
    described_class.instance_variable_set(:@client, original_client)
  end

  it 'configures API key authorization from OPENSEARCH_API_KEY' do
    described_class.client_options = {}

    with_modified_env OPENSEARCH_URL: nil, ELASTICSEARCH_URL: nil,
                      OPENSEARCH_API_KEY: 'opensearch-api-key', ELASTICSEARCH_API_KEY: nil,
                      OPENSEARCH_AWS_ACCESS_KEY_ID: nil, OPENSEARCH_AWS_SECRET_ACCESS_KEY: nil do
      load initializer_path
    end

    expect(described_class.client_options).to eq(
      transport_options: {
        headers: {
          'Authorization' => 'ApiKey opensearch-api-key'
        }
      }
    )
  end

  it 'uses the OpenSearch client for OPENSEARCH_URL' do
    described_class.client_options = {}
    described_class.client_type = nil

    with_modified_env OPENSEARCH_URL: 'http://localhost:9200', ELASTICSEARCH_URL: nil,
                      OPENSEARCH_API_KEY: nil, ELASTICSEARCH_API_KEY: nil,
                      OPENSEARCH_AWS_ACCESS_KEY_ID: nil, OPENSEARCH_AWS_SECRET_ACCESS_KEY: nil do
      load initializer_path
    end

    expect(described_class.queue_name).to eq(:async_database_migration)
    expect(described_class.client_type).to eq(:opensearch)
    expect(described_class.client_options).to eq({})
  end

  it 'uses the Elasticsearch client for ELASTICSEARCH_URL' do
    described_class.client_options = {}
    described_class.client_type = nil

    with_modified_env ELASTICSEARCH_URL: 'https://elastic.example.com', OPENSEARCH_URL: nil,
                      OPENSEARCH_API_KEY: nil, ELASTICSEARCH_API_KEY: nil,
                      OPENSEARCH_AWS_ACCESS_KEY_ID: nil, OPENSEARCH_AWS_SECRET_ACCESS_KEY: nil do
      load initializer_path
    end

    expect(described_class.queue_name).to eq(:async_database_migration)
    expect(described_class.client_type).to eq(:elasticsearch)
    expect(described_class.client_options).to eq(url: 'https://elastic.example.com')
  end

  it 'uses the Elasticsearch client when Elastic API key credentials reuse OPENSEARCH_URL' do
    described_class.client_options = {}
    described_class.client_type = nil

    with_modified_env OPENSEARCH_URL: 'https://elastic.example.com', ELASTICSEARCH_URL: nil,
                      OPENSEARCH_API_KEY: nil, ELASTICSEARCH_API_KEY: 'elastic-api-key',
                      OPENSEARCH_AWS_ACCESS_KEY_ID: nil, OPENSEARCH_AWS_SECRET_ACCESS_KEY: nil do
      load initializer_path
    end

    expect(described_class.queue_name).to eq(:async_database_migration)
    expect(described_class.client_type).to eq(:elasticsearch)
    expect(described_class.client_options).to eq(
      url: 'https://elastic.example.com',
      transport_options: {
        headers: {
          'Authorization' => 'ApiKey elastic-api-key'
        }
      }
    )
  end

  it 'supports ELASTICSEARCH_API_KEY for Elastic Cloud credentials' do
    described_class.client_options = {}

    with_modified_env OPENSEARCH_URL: nil, ELASTICSEARCH_URL: nil,
                      OPENSEARCH_API_KEY: nil, ELASTICSEARCH_API_KEY: 'elastic-api-key',
                      OPENSEARCH_AWS_ACCESS_KEY_ID: nil, OPENSEARCH_AWS_SECRET_ACCESS_KEY: nil do
      load initializer_path
    end

    expect(described_class.client_options).to eq(
      transport_options: {
        headers: {
          'Authorization' => 'ApiKey elastic-api-key'
        }
      }
    )
  end

  it 'removes index settings unsupported by Elastic serverless' do
    described_class.client_type = :elasticsearch
    allow(described_class).to receive(:server_info).and_return('version' => { 'build_flavor' => 'serverless' })

    index_options = Searchkick::Index.new('serverless_test').index_options

    expect(index_options.dig(:settings, :index)).not_to include(:max_ngram_diff, :max_shingle_diff)
    expect(index_options[:settings]).not_to include(:number_of_shards, :number_of_replicas)
    expect(index_options.dig(:settings, :analysis, :filter)).not_to include(
      :searchkick_index_shingle,
      :searchkick_search_shingle,
      :searchkick_suggest_shingle,
      :searchkick_edge_ngram,
      :searchkick_ngram
    )
    expect(index_options.dig(:settings, :analysis, :analyzer)).not_to include(
      :searchkick_suggest_index,
      :searchkick_text_start_index,
      :searchkick_text_middle_index,
      :searchkick_text_end_index,
      :searchkick_word_start_index,
      :searchkick_word_middle_index,
      :searchkick_word_end_index
    )
    index_options.dig(:settings, :analysis, :analyzer).each_value do |analyzer|
      expect(analyzer[:filter]).not_to include(
        'searchkick_index_shingle',
        'searchkick_search_shingle',
        'searchkick_suggest_shingle',
        'searchkick_edge_ngram',
        'searchkick_ngram'
      )
    end
  end

  it 'keeps Searchkick index settings for non-serverless clusters' do
    described_class.client_type = :elasticsearch
    allow(described_class).to receive(:server_info).and_return('version' => { 'build_flavor' => 'default' })

    index_options = Searchkick::Index.new('non_serverless_test').index_options

    expect(index_options.dig(:settings, :index)).to include(
      max_ngram_diff: 49,
      max_shingle_diff: 4
    )
    expect(index_options.dig(:settings, :analysis, :filter)).to include(
      :searchkick_index_shingle,
      :searchkick_edge_ngram,
      :searchkick_ngram
    )
  end
end
