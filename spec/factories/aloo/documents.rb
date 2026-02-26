# frozen_string_literal: true

# == Schema Information
#
# Table name: aloo_documents
#
#  id                :bigint           not null, primary key
#  auto_refresh      :boolean          default(FALSE), not null
#  error_message     :string
#  last_refreshed_at :datetime
#  metadata          :jsonb
#  next_refresh_at   :datetime
#  selected_pages    :jsonb
#  source_type       :string           not null
#  source_url        :string
#  status            :integer          default("pending")
#  text_content      :text
#  title             :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  aloo_assistant_id :bigint           not null
#  article_id        :bigint
#
# Indexes
#
#  index_aloo_documents_on_account_id             (account_id)
#  index_aloo_documents_on_aloo_assistant_id      (aloo_assistant_id)
#  index_aloo_documents_on_article_id             (article_id)
#  index_aloo_documents_on_assistant_and_article  (aloo_assistant_id,article_id) UNIQUE WHERE (article_id IS NOT NULL)
#  index_aloo_documents_on_auto_refresh           (auto_refresh)
#  index_aloo_documents_on_next_refresh_at        (next_refresh_at) WHERE (auto_refresh = true)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (aloo_assistant_id => aloo_assistants.id)
#
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

    trait :with_xlsx do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document.xlsx').open,
          filename: 'test_document.xlsx',
          content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
      end
    end

    trait :with_xls do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document.xls').open,
          filename: 'test_document.xls',
          content_type: 'application/vnd.ms-excel'
        )
      end
    end

    trait :with_docx do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document.docx').open,
          filename: 'test_document.docx',
          content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        )
      end
    end

    trait :with_pptx do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document.pptx').open,
          filename: 'test_document.pptx',
          content_type: 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        )
      end
    end

    trait :with_csv do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document.csv').open,
          filename: 'test_document.csv',
          content_type: 'text/csv'
        )
      end
    end

    trait :with_windows1252_csv do
      after(:build) do |document|
        document.file.attach(
          io: Rails.root.join('spec/fixtures/files/test_document_windows1252.csv').open('rb'),
          filename: 'test_document_windows1252.csv',
          content_type: 'text/csv'
        )
      end
    end
  end
end
