require 'rails_helper'

RSpec.describe Captain::FaqImports::RecoverStalledJob, type: :job do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it 'requeues row processing for a stalled confirmed import' do
    faq_import = confirmed_import
    make_stalled(faq_import)

    expect { described_class.perform_now(faq_import) }
      .to have_enqueued_job(Captain::FaqImports::ProcessJob).with(faq_import)
  end

  it 'requeues a missing embedding for rows that were already saved' do
    faq_import, response = processed_import
    make_stalled(faq_import)

    expect { described_class.perform_now(faq_import) }
      .to have_enqueued_job(Captain::Llm::UpdateEmbeddingJob)
      .with(response, 'New question: New answer', faq_import)
  end

  it 'marks a saved embedding ready without generating it again' do
    faq_import, response = processed_import
    response.update!(embedding: Array.new(1536, 0.1))
    make_stalled(faq_import)

    expect { described_class.perform_now(faq_import) }
      .not_to have_enqueued_job(Captain::Llm::UpdateEmbeddingJob)

    expect(faq_import.reload).to have_attributes(status: 'completed', embedding_ready_count: 1)
  end

  it 'does not recover an import that is still making progress' do
    faq_import = confirmed_import

    expect { described_class.perform_now(faq_import) }
      .not_to have_enqueued_job(Captain::FaqImports::ProcessJob)
  end

  private

  def confirmed_import
    rows = Captain::FaqImports::Parser.new(
      assistant: assistant,
      content: "question,answer\nNew question,New answer\n"
    ).perform
    faq_import = create(
      :captain_faq_import,
      account: account,
      assistant: assistant,
      user: user,
      rows: rows,
      row_count: 1
    )
    faq_import.confirm!([])
    faq_import
  end

  def processed_import
    faq_import = confirmed_import
    response = create(
      :captain_assistant_response,
      assistant: assistant,
      account: account,
      documentable: user,
      question: 'New question',
      answer: 'New answer',
      embedding: nil
    )
    clear_enqueued_jobs
    faq_import.update!(
      rows: faq_import.rows.map { |row| row.merge('response_id' => response.id, 'embedding_state' => 'pending') },
      created_count: 1
    )
    [faq_import, response]
  end

  def make_stalled(faq_import)
    faq_import.update!(updated_at: (Captain::FaqImport::STALLED_AFTER + 1.minute).ago)
  end
end
