require 'rails_helper'

RSpec.describe Captain::ToolsManifest::Validator do
  let(:manifest) do
    {
      'version' => '1.0.0',
      'kind' => 'captain_toolset',
      'name' => 'Shopify Support Tools',
      'category' => 'Commerce',
      'description' => 'Look up Shopify orders for support conversations.',
      'headers' => { 'x-api-version' => '2026-05-01' },
      'inputs' => { 'shop_domain' => { 'label' => 'Shopify store domain', 'required' => true } },
      'secrets' => { 'access_token' => { 'label' => 'Admin API access token', 'type' => 'password', 'required' => true } },
      'tools' => [
        {
          'id' => 'get_order',
          'title' => 'Get Order',
          'description' => 'Retrieve an order by its ID.',
          'http_method' => 'GET',
          'endpoint_url' => 'https://${{ inputs.shop_domain }}/admin/api/orders/{{ order_id }}.json',
          'auth_type' => 'api_key',
          'auth_config' => { 'name' => 'X-Shopify-Access-Token', 'key' => '${{ secrets.access_token }}' },
          'param_schema' => [{ 'name' => 'order_id', 'type' => 'string', 'description' => 'The order ID', 'required' => true }],
          'response_template' => 'Order {{ response.id }} is {{ response.status }}'
        }
      ]
    }
  end
  let(:yaml) { manifest.to_yaml }

  def validate(source = yaml)
    described_class.new(source).perform
  end

  def expect_invalid(source, message)
    expect { validate(source) }.to raise_error(described_class::InvalidManifestError, message)
  end

  describe '#perform' do
    it 'returns the manifest with defaults applied' do
      manifest.except!('category', 'headers')
      manifest['inputs']['shop_domain'].delete('required')

      result = validate

      expect(result['category']).to eq('Others')
      expect(result['headers']).to eq({})
      expect(result['inputs']['shop_domain']).to include('type' => 'string', 'required' => false)
      expect(result['tools'].first['enabled']).to be(true)
    end

    it 'accepts every supported HTTP method' do
      %w[GET POST PUT PATCH DELETE].each do |http_method|
        manifest['tools'].first['http_method'] = http_method

        expect(validate(manifest.to_yaml)['tools'].first['http_method']).to eq(http_method)
      end
    end

    it 'rejects invalid YAML' do
      expect_invalid("version: [1.0.0\n", /Invalid YAML/)
    end

    it 'rejects YAML aliases' do
      expect_invalid("anchor: &a 1\nalias: *a\n", /Invalid YAML/)
    end

    it 'rejects unquoted date values' do
      expect_invalid(yaml.sub("'2026-05-01'", '2026-05-01'), /Invalid YAML/)
    end

    it 'rejects a manifest that is not a mapping' do
      expect_invalid("- one\n- two\n", /must be a YAML object/)
    end

    it 'rejects unknown top-level fields' do
      manifest['schema_version'] = 1

      expect_invalid(yaml, /Unknown toolset fields: schema_version/)
    end

    it 'rejects the wrong kind' do
      manifest['kind'] = 'toolset'

      expect_invalid(yaml, /kind must be captain_toolset/)
    end

    it 'rejects a version that is not semantic' do
      manifest['version'] = '1.0'

      expect_invalid(yaml, /semantic version/)
    end

    it 'rejects a name that is too long' do
      manifest['name'] = 'a' * 101

      expect_invalid(yaml, /name must be 1-100 characters/)
    end

    it 'rejects an unknown category' do
      manifest['category'] = 'Productivity'

      expect_invalid(yaml, /category must be one of/)
    end

    it 'rejects an empty tool list' do
      manifest['tools'] = []

      expect_invalid(yaml, /1-50 tools/)
    end

    it 'rejects reserved headers' do
      manifest['headers'] = { 'Authorization' => 'Bearer abc' }

      expect_invalid(yaml, /Authorization/)
    end

    it 'rejects input definitions without a label' do
      manifest['inputs']['shop_domain'].delete('label')

      expect_invalid(yaml, /shop_domain label must be 1-80 characters/)
    end

    it 'rejects unknown input definition fields' do
      manifest['inputs']['shop_domain']['default'] = 'acme'

      expect_invalid(yaml, /Unknown input shop_domain fields: default/)
    end

    it 'rejects an unsupported input type' do
      manifest['secrets']['access_token']['type'] = 'file'

      expect_invalid(yaml, /access_token type must be one of/)
    end

    it 'rejects unknown tool fields' do
      manifest['tools'].first['timeout'] = 5

      expect_invalid(yaml, /Unknown tool get_order fields: timeout/)
    end

    it 'rejects tool ids that are not snake_case' do
      manifest['tools'].first['id'] = 'GetOrder'

      expect_invalid(yaml, /Invalid tool id: GetOrder/)
    end

    it 'rejects duplicate tool ids' do
      manifest['tools'] << manifest['tools'].first.deep_dup

      expect_invalid(yaml, /Duplicate tool id: get_order/)
    end

    it 'rejects an unsupported HTTP method' do
      manifest['tools'].first['http_method'] = 'HEAD'

      expect_invalid(yaml, /get_order http_method must be one of/)
    end

    it 'rejects an auth_config missing credentials for its auth_type' do
      manifest['tools'].first['auth_config'].delete('name')

      expect_invalid(yaml, /get_order auth_config must include name and key for api_key/)
    end

    it 'rejects undeclared install-time placeholders' do
      manifest['tools'].first['endpoint_url'] = 'https://${{ inputs.store }}/orders/{{ order_id }}'

      expect_invalid(yaml, /undeclared placeholder inputs.store/)
    end

    it 'rejects install-time placeholders outside the allowed fields' do
      manifest['tools'].first['title'] = 'Orders for ${{ inputs.shop_domain }}'

      expect_invalid(yaml, /get_order title cannot contain install-time placeholders/)
    end

    it 'rejects call-time placeholders without a matching parameter' do
      manifest['tools'].first['endpoint_url'] = 'https://${{ inputs.shop_domain }}/orders/{{ order_number }}'

      expect_invalid(yaml, /undeclared parameter order_number/)
    end

    it 'rejects invalid Liquid in the response template' do
      manifest['tools'].first['response_template'] = 'Order {{ response.id '

      expect_invalid(yaml, /get_order response_template is not valid Liquid/)
    end
  end
end
