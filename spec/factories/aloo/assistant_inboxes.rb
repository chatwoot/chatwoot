# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_assistant_inbox, class: 'Aloo::AssistantInbox' do
    association :assistant, factory: :aloo_assistant
    inbox
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
