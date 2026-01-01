# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_memory, class: 'Aloo::Memory' do
    account
    association :assistant, factory: :aloo_assistant
    memory_type { 'preference' }
    content { Faker::Lorem.sentence }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }
    confidence { 0.7 }
    observation_count { 1 }
    last_observed_at { Time.current }
    entities { [] }
    topics { [] }
    helpful_count { 0 }
    not_helpful_count { 0 }
    flagged_for_review { false }

    # Contact-scoped memory types
    trait :preference do
      memory_type { 'preference' }
      contact
    end

    trait :commitment do
      memory_type { 'commitment' }
      contact
    end

    trait :decision do
      memory_type { 'decision' }
      contact
    end

    trait :correction do
      memory_type { 'correction' }
      contact
    end

    # Global memory types
    trait :faq do
      memory_type { 'faq' }
      contact { nil }
    end

    trait :procedure do
      memory_type { 'procedure' }
      contact { nil }
    end

    trait :insight do
      memory_type { 'insight' }
      contact { nil }
    end

    trait :gap do
      memory_type { 'gap' }
      contact { nil }
    end

    # Confidence traits
    trait :low_confidence do
      confidence { 0.1 }
    end

    trait :high_confidence do
      confidence { 0.95 }
    end

    trait :below_threshold do
      confidence { 0.15 }
    end

    # Feedback traits
    trait :well_received do
      helpful_count { 5 }
      not_helpful_count { 0 }
      confidence { 0.9 }
    end

    trait :poorly_received do
      helpful_count { 0 }
      not_helpful_count { 4 }
      confidence { 0.3 }
      flagged_for_review { true }
    end

    trait :without_embedding do
      embedding { nil }
    end

    trait :with_entities do
      entities { ['product_name', 'order_id'] }
    end

    trait :with_topics do
      topics { ['billing', 'refund'] }
    end
  end
end
