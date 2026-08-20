require 'rails_helper'

RSpec.describe Captain::FaqImports::ProcessJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:embedding) { Array.new(1536, 0.1) }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService, get_embedding: embedding) }

  before do
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'creates new FAQs and finishes after their embeddings are ready' do
    faq_import = confirmed_import("question,answer\nNew question,New answer\n")

    described_class.perform_now(faq_import)

    created = assistant.responses.find_by!(question: 'New question')
    expect(created).to have_attributes(documentable: user, embedding: nil)
    expect(faq_import.reload).to have_attributes(status: 'preparing', created_count: 1, skipped_count: 0)

    perform_enqueued_jobs(only: Captain::Llm::UpdateEmbeddingJob)

    expect(created.reload.embedding).to be_present
    expect(faq_import.reload).to have_attributes(status: 'completed', embedding_ready_count: 1, embedding_failed_count: 0)
  end

  it 'purges the original CSV after saving the FAQ rows' do
    faq_import = confirmed_import("question,answer\nNew question,New answer\n")
    faq_import.source_file.attach(io: StringIO.new('csv'), filename: 'faqs.csv', content_type: 'text/csv')

    described_class.perform_now(faq_import)

    expect(faq_import.reload.source_file).not_to be_attached
  end

  it 'skips existing FAQs by default' do
    existing = create(:captain_assistant_response, assistant: assistant, question: 'Existing question', answer: 'Old answer')
    faq_import = confirmed_import("question,answer\nExisting question,Imported answer\n")

    described_class.perform_now(faq_import)

    expect(existing.reload.answer).to eq('Old answer')
    expect(faq_import.reload).to have_attributes(status: 'completed', created_count: 0, overwritten_count: 0, skipped_count: 1)
  end

  it 'overwrites an existing FAQ in place, makes it manual, and clears its stale embedding' do
    document = create(:captain_document, account: account, assistant: assistant)
    existing = create(
      :captain_assistant_response,
      assistant: assistant,
      documentable: document,
      question: 'Existing question',
      answer: 'Old answer'
    )
    original_id = existing.id
    faq_import = confirmed_import("question,answer\nExisting question,Imported answer\n", overwrite_rows: [2])

    described_class.perform_now(faq_import)

    expect(existing.reload).to have_attributes(
      id: original_id,
      answer: 'Imported answer',
      documentable: user,
      embedding: nil
    )
    expect(faq_import.reload).to have_attributes(status: 'preparing', overwritten_count: 1)
  end

  it 'does not overwrite a replacement FAQ that was not shown in the preview' do
    previewed = create(
      :captain_assistant_response,
      assistant: assistant,
      question: 'Existing question',
      answer: 'Previewed answer'
    )
    faq_import = confirmed_import("question,answer\nExisting question,Imported answer\n", overwrite_rows: [2])
    previewed.update!(question: 'Renamed question')
    replacement = create(
      :captain_assistant_response,
      assistant: assistant,
      question: 'Existing question',
      answer: 'Replacement answer'
    )

    described_class.perform_now(faq_import)

    expect(previewed.reload.answer).to eq('Previewed answer')
    expect(replacement.reload.answer).to eq('Replacement answer')
    expect(faq_import.reload).to have_attributes(status: 'completed', overwritten_count: 0, skipped_count: 1)
  end

  it 'does not overwrite an FAQ created after the preview' do
    faq_import = confirmed_import("question,answer\nNew question,Imported answer\n")
    existing = create(:captain_assistant_response, assistant: assistant, question: 'NEW QUESTION', answer: 'Manual answer')

    described_class.perform_now(faq_import)

    expect(existing.reload.answer).to eq('Manual answer')
    expect(faq_import.reload).to have_attributes(status: 'completed', created_count: 0, overwritten_count: 0, skipped_count: 1)
  end

  it 'does not process the same import twice while embeddings are pending' do
    faq_import = confirmed_import("question,answer\nNew question,New answer\n")

    expect do
      described_class.perform_now(faq_import)
      described_class.perform_now(faq_import.reload)
    end.to change(Captain::AssistantResponse, :count).by(1)

    expect(faq_import.reload).to have_attributes(status: 'preparing', created_count: 1)
  end

  it 'marks the import completed with errors when an embedding fails' do
    allow(embedding_service).to receive(:get_embedding).and_raise(Captain::Llm::EmbeddingService::EmbeddingsError, 'failed')
    faq_import = confirmed_import("question,answer\nNew question,New answer\n")

    described_class.perform_now(faq_import)
    3.times { perform_enqueued_jobs(only: Captain::Llm::UpdateEmbeddingJob) }

    expect(faq_import.reload).to have_attributes(
      status: 'completed_with_errors',
      embedding_ready_count: 0,
      embedding_failed_count: 1
    )
  end

  private

  def confirmed_import(content, overwrite_rows: [])
    rows = Captain::FaqImports::Parser.new(assistant: assistant, content: content).perform
    faq_import = create(
      :captain_faq_import,
      account: account,
      assistant: assistant,
      user: user,
      rows: rows,
      row_count: rows.length
    )
    faq_import.confirm!(overwrite_rows)
    faq_import
  end
end
