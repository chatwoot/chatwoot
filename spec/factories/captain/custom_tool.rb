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
      auth_config { { key: 'test_api_key', location: 'header', name: 'X-API-Key' } }
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
  end
end
