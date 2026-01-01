# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_conversation_context, class: 'Aloo::ConversationContext' do
    conversation
    association :assistant, factory: :aloo_assistant
    context_data { {} }
    tool_history { [] }
    message_count { 0 }
    input_tokens { 0 }
    output_tokens { 0 }
    total_cost { 0.0 }

    trait :with_usage do
      message_count { 5 }
      input_tokens { 1000 }
      output_tokens { 500 }
      total_cost { 0.001 }
    end

    trait :with_tool_history do
      tool_history do
        [
          {
            'tool' => 'faq_lookup',
            'input' => { 'query' => 'return policy' },
            'output' => { 'results' => [] },
            'success' => true,
            'timestamp' => Time.current.iso8601
          }
        ]
      end
    end

    trait :with_multiple_tools do
      tool_history do
        [
          {
            'tool' => 'faq_lookup',
            'input' => { 'query' => 'return policy' },
            'output' => { 'results' => ['Policy info'] },
            'success' => true,
            'timestamp' => 1.minute.ago.iso8601
          },
          {
            'tool' => 'handoff',
            'input' => { 'reason' => 'Customer requested human' },
            'output' => { 'assigned_to' => 1 },
            'success' => true,
            'timestamp' => Time.current.iso8601
          }
        ]
      end
    end

    trait :with_context_data do
      context_data do
        {
          'memory_extraction_completed' => true,
          'faq_generation_completed' => false,
          'last_topic' => 'billing'
        }
      end
    end

    trait :overflow do
      message_count { 55 }
    end

    trait :high_usage do
      message_count { 20 }
      input_tokens { 50_000 }
      output_tokens { 25_000 }
      total_cost { 0.05 }
    end
  end
end
