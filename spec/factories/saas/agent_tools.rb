# frozen_string_literal: true

FactoryBot.define do
  factory :agent_tool, class: 'Saas::AgentTool' do
    ai_agent factory: :ai_agent
    account { ai_agent.account }
    sequence(:name) { |n| "Tool #{n}" }
    description { 'A test tool' }
    tool_type { :http }
    http_method { 'POST' }
    url_template { 'https://api.example.com/endpoint' }
    headers_template { {} }
    body_template { '{"key": "value"}' }
    parameters_schema { { 'type' => 'object', 'properties' => {} } }
    auth_type { nil }
    auth_token { nil }
    active { true }
    config { {} }

    trait :inactive do
      active { false }
    end

    trait :with_auth do
      auth_type { 'bearer' }
      auth_token { 'test-token-123' }
    end

    trait :handoff do
      tool_type { :handoff }
      name { 'handoff_to_human' }
      url_template { nil }
    end

    trait :built_in do
      tool_type { :built_in }
    end
  end
end
