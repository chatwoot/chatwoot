FactoryBot.define do
  factory :knowledge_base do
    id { SecureRandom.uuid }
    account
    name { 'Sample Knowledge Base' }
    source_type { 'file' }
    url { 'https://example.com/sample-file.pdf' }

    trait :webpage do
      source_type { 'webpage' }
      url { 'https://example.com/documentation' }
    end

    trait :image do
      source_type { 'image' }
      url { 'https://example.com/sample-image.png' }
    end

    trait :file do
      source_type { 'file' }
      url { 'https://example.com/sample-document.pdf' }
    end
  end
end