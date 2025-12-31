# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_assistant, class: 'Aloo::Assistant' do
    account
    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    tone { 'friendly' }
    formality { 'medium' }
    empathy_level { 'medium' }
    verbosity { 'balanced' }
    emoji_usage { 'minimal' }
    greeting_style { 'warm' }
    language { 'en' }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :arabic do
      language { 'ar' }
      dialect { 'EG' }
    end

    trait :professional do
      tone { 'professional' }
      formality { 'high' }
    end
  end
end
