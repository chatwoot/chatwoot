# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_document, class: 'Aloo::Document' do
    account
    association :assistant, factory: :aloo_assistant
    title { Faker::Lorem.sentence(word_count: 3) }
    source_type { 'file' }
    status { :pending }
    metadata { {} }

    trait :processing do
      status { :processing }
    end

    trait :available do
      status { :available }
      title { Faker::Lorem.sentence(word_count: 3) }
    end

    trait :failed do
      status { :failed }
      error_message { 'Processing failed: Unable to extract content' }
    end

    trait :unsupported do
      status { :unsupported }
      error_message { 'File type not supported' }
    end

    trait :website do
      source_type { 'website' }
      source_url { Faker::Internet.url }
    end

    trait :with_file do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new('This is test document content for embedding.'),
          filename: 'test_document.txt',
          content_type: 'text/plain'
        )
      end
    end

    trait :with_pdf do
      after(:build) do |document|
        document.file.attach(
          io: StringIO.new('%PDF-1.4 fake pdf content'),
          filename: 'test_document.pdf',
          content_type: 'application/pdf'
        )
      end
    end
  end
end
