# frozen_string_literal: true

FactoryBot.define do
  factory :ai_agent_inbox, class: 'Saas::AiAgentInbox' do
    ai_agent factory: :ai_agent
    inbox
    auto_reply { true }
    status { :active }

    trait :paused do
      status { :paused }
    end
  end
end
