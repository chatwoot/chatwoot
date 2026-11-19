require 'rails_helper'

RSpec.describe Migration::MoveCaptainResponseEmbeddingsInRowJob, type: :job do
  it 'rewrites one batch with identical values and schedules the next batch' do
    first = create_list(:captain_assistant_response, 2).map(&:reload).min_by(&:id)
    embedding = first.embedding
    updated_at = first.updated_at

    expect { described_class.perform_now(batch_size: 1) }
      .to have_enqueued_job(described_class).with(after_id: first.id, batch_size: 1, pause_seconds: 2)

    first.reload
    expect(first.embedding).to eq(embedding)
    expect(first.updated_at).to eq(updated_at)
  end

  it 'stops when no rows are left' do
    response = create(:captain_assistant_response)

    expect { described_class.perform_now(after_id: response.id) }.not_to have_enqueued_job(described_class)
  end
end
