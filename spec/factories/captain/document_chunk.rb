FactoryBot.define do
  factory :captain_document_chunk, class: 'Captain::DocumentChunk' do
    association :document, factory: :captain_document
    assistant { document.assistant }
    account { document.account }
    content { 'Chunk content' }
    add_attribute(:context) { 'Chunk context' }
    embedding { Array.new(1536, 0.1) }
    position { 0 }
    token_count { 12 }
  end
end
