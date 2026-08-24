FactoryBot.define do
  factory :captain_custom_tool, class: 'Captain::CustomTool' do
    sequence(:title) { |n| "Custom Tool #{n}" }
    description { 'A custom HTTP tool for external API integration' }
    endpoint_url { 'https://api.example.com/endpoint' }
    http_method { 'GET' }
    auth_type { 'none' }
    auth_config { {} }
    param_schema { [] }
    enabled { true }
    association :account

    trait :with_post do
      http_method { 'POST' }
      request_template { '{ "key": "{{ value }}" }' }
    end

    trait :with_bearer_auth do
      auth_type { 'bearer' }
      auth_config { { token: 'test_bearer_token_123' } }
    end

    trait :with_basic_auth do
      auth_type { 'basic' }
      auth_config { { username: 'test_user', password: 'test_pass' } }
    end

    trait :with_api_key do
      auth_type { 'api_key' }
      auth_config { { key: 'test_api_key', name: 'X-API-Key' } }
    end

    trait :with_templates do
      request_template { '{ "order_id": "{{ order_id }}", "source": "chatwoot" }' }
      response_template { 'Order status: {{ response.status }}' }
    end

    trait :with_params do
      param_schema do
        [
          { 'name' => 'order_id', 'type' => 'string', 'description' => 'The order ID', 'required' => true },
          { 'name' => 'include_details', 'type' => 'boolean', 'description' => 'Include order details', 'required' => false }
        ]
      end
    end

    trait :disabled do
      enabled { false }
    end

    trait :catalog do
      source_kind { 'catalog' }
      provider_key { 'stripe' }
      category_key { 'customers' }
      sequence(:template_key) { |n| "find_customer_#{n}" }
      template_version { '1.0.0' }
      definition_digest { "sha256:#{'a' * 64}" }
      definition do
        {
          'allowed_origins' => ['https://api.example.com'],
          'operations' => [{
            'key' => 'find_customer',
            'source' => 'openapi',
            'scopes' => ['customers:read'],
            'definition' => {},
            'request' => {
              'method' => 'GET',
              'url' => 'https://api.example.com/customers',
              'encoding' => 'query',
              'parameters' => []
            }
          }],
          'recipe' => [{ 'operation_key' => 'find_customer', 'bindings' => {} }]
        }
      end
      configuration { {} }
      input_schema { { 'type' => 'object', 'additionalProperties' => false, 'properties' => {} } }
      output_schema { { 'type' => 'object', 'additionalProperties' => false, 'properties' => {} } }
      risk_class { 'read' }
      endpoint_url { nil }
      auth_config { {} }
    end
  end
end
