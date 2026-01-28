# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_embedding, class: 'Aloo::Embedding' do
    account
    association :assistant, factory: :aloo_assistant
    association :document, factory: :aloo_document
    content { Faker::Lorem.paragraph(sentence_count: 3) }
    embedding { Array.new(1536) { rand(-1.0..1.0) } }
    metadata { { 'chunk_index' => 0, 'token_count' => 100, 'model' => 'text-embedding-3-small' } }

    trait :without_embedding do
      embedding { nil }
    end

    trait :without_document do
      document { nil }
    end

    trait :with_source_url do
      association :document, factory: [:aloo_document, :website, :available]
    end
  end
end
