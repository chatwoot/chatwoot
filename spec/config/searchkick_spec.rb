require 'rails_helper'

RSpec.describe Searchkick do
  let(:initializer_path) { Rails.root.join('config/initializers/searchkick.rb') }

  around do |example|
    original_client_options = described_class.client_options.deep_dup
    original_queue_name = described_class.queue_name
    original_aws_credentials = described_class.aws_credentials
    original_client = described_class.instance_variable_get(:@client)

    example.run
  ensure
    described_class.client_options = original_client_options
    described_class.queue_name = original_queue_name
    described_class.instance_variable_set(:@aws_credentials, original_aws_credentials)
    described_class.instance_variable_set(:@client, original_client)
  end

  it 'configures API key authorization from OPENSEARCH_API_KEY' do
    described_class.client_options = {}

    with_modified_env OPENSEARCH_API_KEY: 'opensearch-api-key', ELASTICSEARCH_API_KEY: nil,
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

  it 'supports ELASTICSEARCH_API_KEY for Elastic Cloud credentials' do
    described_class.client_options = {}

    with_modified_env OPENSEARCH_API_KEY: nil, ELASTICSEARCH_API_KEY: 'elastic-api-key',
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
end
