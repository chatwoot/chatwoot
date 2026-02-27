# frozen_string_literal: true

# == Schema Information
#
# Table name: aloo_embeddings
#
#  id                :bigint           not null, primary key
#  content           :text             not null
#  embedding         :vector(1536)
#  metadata          :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  aloo_assistant_id :bigint           not null
#  aloo_document_id  :bigint
#
# Indexes
#
#  aloo_embeddings_embedding_idx               (embedding) USING hnsw
#  index_aloo_embeddings_on_account_id         (account_id)
#  index_aloo_embeddings_on_aloo_assistant_id  (aloo_assistant_id)
#  index_aloo_embeddings_on_aloo_document_id   (aloo_document_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (aloo_assistant_id => aloo_assistants.id)
#  fk_rails_...  (aloo_document_id => aloo_documents.id)
#
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
