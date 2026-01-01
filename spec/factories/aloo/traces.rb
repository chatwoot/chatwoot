# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_trace, class: 'Aloo::Trace' do
    account
    association :assistant, factory: :aloo_assistant
    conversation { nil }
    trace_type { 'agent_call' }
    request_id { SecureRandom.uuid }
    success { true }
    duration_ms { rand(100..5000) }
    input_data { {} }
    output_data { {} }
    input_tokens { nil }
    output_tokens { nil }
    error_message { nil }

    trait :failed do
      success { false }
      error_message { 'API request failed: timeout' }
    end

    trait :agent_call do
      trace_type { 'agent_call' }
      input_tokens { 500 }
      output_tokens { 200 }
      input_data { { 'model' => 'gemini-2.0-flash', 'temperature' => 0.7 } }
      output_data { { 'finish_reason' => 'stop' } }
    end

    trait :search do
      trace_type { 'search' }
      input_data { { 'query' => 'test query', 'limit' => 10 } }
      output_data { { 'result_count' => 5 } }
    end

    trait :embedding do
      trace_type { 'embedding' }
      input_data { { 'text_length' => 500, 'chunk_index' => 0 } }
      output_data { { 'dimensions' => 1536 } }
    end

    trait :tool_execution do
      trace_type { 'tool_execution' }
      input_data { { 'tool' => 'faq_lookup', 'arguments' => { 'query' => 'test' } } }
      output_data { { 'result' => 'Found 3 matches' } }
    end

    trait :with_conversation do
      conversation
    end

    trait :slow do
      duration_ms { 30_000 }
    end

    trait :fast do
      duration_ms { 50 }
    end

    trait :recent do
      created_at { 1.hour.ago }
    end

    trait :old do
      created_at { 2.days.ago }
    end
  end
end
