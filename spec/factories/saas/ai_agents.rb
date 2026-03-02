# frozen_string_literal: true

FactoryBot.define do
  factory :ai_agent, class: 'Saas::AiAgent' do
    account
    sequence(:name) { |n| "AI Agent #{n}" }
    agent_type { :rag }
    status { :active }
    model { 'gpt-4.1-mini' }
    system_prompt { 'You are a helpful assistant.' }
    llm_config { { 'temperature' => 0.7, 'max_tokens' => 4096 } }
    voice_config { {} }
    config { {} }

    trait :tool_calling do
      agent_type { :tool_calling }
    end

    trait :voice do
      agent_type { :voice }
      voice_config do
        { 'provider' => 'openai', 'voice' => 'alloy', 'language' => 'en' }
      end
    end

    trait :hybrid do
      agent_type { :hybrid }
    end

    trait :paused do
      status { :paused }
    end

    trait :archived do
      status { :archived }
    end
  end
end
