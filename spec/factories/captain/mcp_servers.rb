FactoryBot.define do
  factory :captain_mcp_server, class: 'Captain::McpServer' do
    sequence(:name) { |n| "MCP Server #{n}" }
    description { 'A test MCP server' }
    url { 'https://mcp.example.com/api' }
    auth_type { 'none' }
    auth_config { {} }
    enabled { true }
    status { 'disconnected' }
    association :account

    trait :with_bearer_auth do
      auth_type { 'bearer' }
      auth_config { { 'token' => 'test_bearer_token_123' } }
    end

    trait :with_api_key do
      auth_type { 'api_key' }
      auth_config { { 'key' => 'test_api_key', 'header_name' => 'X-API-Key' } }
    end

    trait :connected do
      status { 'connected' }
      last_connected_at { Time.current }
      cached_tools do
        [
          {
            'name' => 'search_docs',
            'description' => 'Search documentation',
            'inputSchema' => {
              'type' => 'object',
              'properties' => {
                'query' => { 'type' => 'string', 'description' => 'Search query' }
              },
              'required' => ['query']
            }
          },
          {
            'name' => 'get_page',
            'description' => 'Get a specific page',
            'inputSchema' => {
              'type' => 'object',
              'properties' => {
                'url' => { 'type' => 'string', 'description' => 'Page URL' }
              },
              'required' => ['url']
            }
          }
        ]
      end
      cache_refreshed_at { Time.current }
    end

    trait :with_error do
      status { 'error' }
      last_error { 'Connection refused' }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
