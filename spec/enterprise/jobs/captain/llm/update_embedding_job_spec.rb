require 'rails_helper'

RSpec.describe Captain::Llm::UpdateEmbeddingJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:response) { create(:captain_assistant_response, account: account, assistant: assistant, embedding: nil) }
  let(:faq_import) do
    create(
      :captain_faq_import,
      account: account,
      assistant: assistant,
      user: user,
      status: :preparing,
      confirmed_at: Time.current,
      row_count: 1,
      created_count: 1,
      rows: [
        {
          'row_number' => 2,
          'state' => Captain::FaqImport::ROW_STATES[:valid],
          'response_id' => response.id,
          'embedding_state' => Captain::FaqImport::EMBEDDING_STATES[:pending]
        }
      ]
    )
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'finishes an import when its FAQ is deleted before embedding starts' do
    response_id = response.id
    response.destroy!

    described_class.perform_now(response_id, 'Question: Answer', faq_import)

    expect(faq_import.reload).to have_attributes(
      status: 'completed_with_errors',
      embedding_ready_count: 0,
      embedding_failed_count: 1
    )
  end

  it 'retries imported FAQ embedding failures without marking them failed' do
    embedding_service = instance_double(Captain::Llm::EmbeddingService)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_raise(
      Captain::Llm::EmbeddingService::EmbeddingsError,
      'Provider timeout'
    )
    response_id = response.id
    import = faq_import
    clear_enqueued_jobs

    expect do
      described_class.perform_now(response_id, 'Question: Answer', import)
    end.to have_enqueued_job(described_class)

    expect(import.reload).to have_attributes(
      status: 'preparing',
      embedding_ready_count: 0,
      embedding_failed_count: 0
    )
    expect(import.rows.first['embedding_state']).to eq(Captain::FaqImport::EMBEDDING_STATES[:pending])
  end

  it 'marks an imported FAQ embedding failed after retries are exhausted' do
    embedding_service = instance_double(Captain::Llm::EmbeddingService)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_raise(
      Captain::Llm::EmbeddingService::EmbeddingsError,
      'Provider timeout'
    )
    job = described_class.new(response.id, 'Question: Answer', faq_import)
    job.exception_executions = { [described_class::ImportEmbeddingError].to_s => 2 }

    expect { job.perform_now }.not_to have_enqueued_job(described_class)

    expect(faq_import.reload).to have_attributes(
      status: 'completed_with_errors',
      embedding_ready_count: 0,
      embedding_failed_count: 1
    )
  end

  it 'does not hide unexpected failures while embedding an imported FAQ' do
    embedding_service = instance_double(Captain::Llm::EmbeddingService)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(embedding_service).to receive(:get_embedding).and_raise(ActiveRecord::ConnectionNotEstablished, 'database unavailable')

    expect do
      described_class.perform_now(response.id, 'Question: Answer', faq_import)
    end.to raise_error(ActiveRecord::ConnectionNotEstablished, 'database unavailable')

    expect(faq_import.reload).to have_attributes(status: 'preparing', embedding_ready_count: 0, embedding_failed_count: 0)
  end
end
