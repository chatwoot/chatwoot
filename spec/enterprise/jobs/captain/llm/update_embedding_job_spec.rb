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

  shared_examples 'safe ordinary embeddings' do |content_attributes|
    let(:old_embedding) { [1.0] + Array.new(1535, 0.0) }
    let(:new_embedding) { old_embedding.reverse }
    let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService, get_embedding: new_embedding) }
    let(:content) { content_attributes.map { |attribute| record.public_send(attribute) }.join(': ') }

    before do
      allow(Captain::Llm::EmbeddingService).to receive(:new).with(account_id: account.id).and_return(embedding_service)
    end

    it 'saves an embedding for unchanged content' do
      described_class.perform_now(record, content)

      expect(record.reload.embedding).to eq(new_embedding)
    end

    it 'discards content queued before an edit' do
      queued_content = content
      record.update!(content_attributes.first => 'Edited before execution', :embedding => new_embedding)
      allow(embedding_service).to receive(:get_embedding).with(queued_content).and_return(old_embedding)

      described_class.perform_now(record, queued_content)

      expect(record.reload.embedding).to eq(new_embedding)
    end

    content_attributes.each do |attribute|
      it "preserves the newer job's embedding when #{attribute} changes during generation" do
        queued_content = content
        allow(embedding_service).to receive(:get_embedding).with(queued_content) do
          record.update!(attribute => 'Edited during generation')
          updated_content = content_attributes.map { |field| record.public_send(field) }.join(': ')
          described_class.perform_now(record.class.find(record.id), updated_content)
          expect(record.reload.embedding).to eq(new_embedding)
          clear_enqueued_jobs
          old_embedding
        end

        described_class.perform_now(record.class.find(record.id), queued_content)

        expect(record.reload.embedding).to eq(new_embedding)
        expect(enqueued_jobs).to be_empty
      end
    end

    it 'discards the result when the record is deleted during generation' do
      allow(embedding_service).to receive(:get_embedding).with(content) do
        record.destroy!
        old_embedding
      end

      expect { described_class.perform_now(record.class.find(record.id), content) }.not_to raise_error
      expect(record.class).not_to exist(record.id)
    end

    it 'leaves ordinary provider failures available for retry' do
      allow(embedding_service).to receive(:get_embedding).and_raise(Captain::Llm::EmbeddingService::EmbeddingsError, 'Provider timeout')

      expect { described_class.perform_now(record, content) }.to raise_error(Captain::Llm::EmbeddingService::EmbeddingsError)
      expect(record.reload.embedding).to be_nil
    end
  end

  context 'with an ordinary FAQ job' do
    let(:record) { response }

    it_behaves_like 'safe ordinary embeddings', %i[question answer]
  end

  context 'with an ordinary FAQ suggestion job' do
    let(:record) do
      Captain::FaqSuggestion.create!(account: account, assistant: assistant, question: 'Question', answer: 'Answer')
    end

    it_behaves_like 'safe ordinary embeddings', %i[question answer]
  end

  context 'with an ordinary article embedding job' do
    let(:record) do
      ArticleEmbedding.create!(article: create(:article, account: account, portal: create(:portal, account: account)), term: 'Article text')
    end

    it_behaves_like 'safe ordinary embeddings', [:term]
  end

  context 'when imported FAQ content changes' do
    let(:old_embedding) { [1.0] + Array.new(1535, 0.0) }
    let(:new_embedding) { old_embedding.reverse }
    let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

    before do
      allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    end

    it 'preserves the imported embedding when an older ordinary job finishes last' do
      old_content = "#{response.question}: #{response.answer}"
      new_content = "#{response.question}: Within two days."
      import = create(:captain_faq_import, account: account, assistant: assistant, user: user,
                                           status: :preparing, confirmed_at: Time.current, row_count: 1,
                                           rows: [{ 'row_number' => 2, 'state' => 'existing',
                                                    'question' => response.question, 'answer' => 'Within two days.',
                                                    'normalized_question' => Captain::FaqImports::Parser.normalize(response.question),
                                                    'existing_id' => response.id, 'existing_answer' => response.answer,
                                                    'resolution' => 'overwrite' }])
      allow(embedding_service).to receive(:get_embedding).with(new_content).and_return(new_embedding)
      allow(embedding_service).to receive(:get_embedding).with(old_content) do
        Captain::FaqImports::ProcessJob.perform_now(import)
        described_class.perform_now(response.id, new_content, import.reload)
        expect(response.reload.embedding).to eq(new_embedding)
        expect(import.reload).to have_attributes(status: 'completed', overwritten_count: 1, embedding_ready_count: 1)
        clear_enqueued_jobs
        old_embedding
      end

      described_class.perform_now(Captain::AssistantResponse.find(response.id), old_content)

      expect(response.reload.answer).to eq('Within two days.')
      expect(import.reload.status).to eq('completed')
      expect(enqueued_jobs).to be_empty
      expect([response.embedding.first, response.embedding.last]).to eq([0.0, 1.0])
    end

    it 'discards content queued before an edit' do
      content = "#{response.question}: #{response.answer}"
      response.update!(answer: 'Edited after import', embedding: new_embedding)
      allow(embedding_service).to receive(:get_embedding).with(content).and_return(old_embedding)

      described_class.perform_now(response.id, content, faq_import)

      expect(response.reload.embedding).to eq(new_embedding)
      expect(faq_import.reload).to have_attributes(status: 'completed_with_errors', embedding_ready_count: 0, embedding_failed_count: 1)
    end

    %i[question answer].each do |attribute|
      it "discards the result when the #{attribute} changes during generation" do
        content = "#{response.question}: #{response.answer}"
        allow(embedding_service).to receive(:get_embedding).with(content) do
          response.update!(attribute => 'Edited during generation', :embedding => new_embedding)
          old_embedding
        end

        described_class.perform_now(response.id, content, faq_import)

        expect(response.reload.embedding).to eq(new_embedding)
        expect(faq_import.reload).to have_attributes(status: 'completed_with_errors', embedding_ready_count: 0, embedding_failed_count: 1)
      end
    end

    it 'finishes with an error if the FAQ is deleted during generation' do
      content = "#{response.question}: #{response.answer}"
      allow(embedding_service).to receive(:get_embedding).with(content) do
        response.destroy!
        old_embedding
      end

      described_class.perform_now(response.id, content, faq_import)

      expect(faq_import.reload).to have_attributes(status: 'completed_with_errors', embedding_ready_count: 0, embedding_failed_count: 1)
    end
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
