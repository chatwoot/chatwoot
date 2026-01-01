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
    system_prompt { 'You are a helpful customer support assistant.' }
    admin_config { {} }

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

    trait :with_faq_enabled do
      admin_config { { 'feature_faq' => true } }
    end

    trait :with_memory_enabled do
      admin_config { { 'feature_memory' => true } }
    end

    trait :with_all_features do
      admin_config { { 'feature_faq' => true, 'feature_memory' => true } }
    end

    trait :with_custom_model do
      admin_config { { 'model' => 'gpt-4o', 'temperature' => 0.5 } }
    end
  end
end
