FactoryBot.define do
  factory :captain_assistant_mcp_server, class: 'Captain::AssistantMcpServer' do
    association :assistant, factory: :captain_assistant
    association :mcp_server, factory: :captain_mcp_server
    enabled { true }
    tool_filters { {} }

    trait :with_include_filter do
      tool_filters { { 'include' => ['search_docs'] } }
    end

    trait :with_exclude_filter do
      tool_filters { { 'exclude' => ['get_page'] } }
    end

    trait :with_both_filters do
      tool_filters { { 'include' => %w[search_docs get_page], 'exclude' => ['get_page'] } }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
