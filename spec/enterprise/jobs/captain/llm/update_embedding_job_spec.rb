require 'rails_helper'

RSpec.describe Captain::Llm::UpdateEmbeddingJob, type: :job do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  it 'finishes an import when its FAQ is deleted before embedding starts' do
    response = create(:captain_assistant_response, account: account, assistant: assistant, embedding: nil)
    faq_import = create(
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
    response_id = response.id
    response.destroy!

    described_class.perform_now(response_id, 'Question: Answer', faq_import)

    expect(faq_import.reload).to have_attributes(
      status: 'completed_with_errors',
      embedding_ready_count: 0,
      embedding_failed_count: 1
    )
  end
end
