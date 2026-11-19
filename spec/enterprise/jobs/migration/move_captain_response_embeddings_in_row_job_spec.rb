require 'rails_helper'

RSpec.describe Migration::MoveCaptainResponseEmbeddingsInRowJob, type: :job do
  it 'rewrites each embedding without changing it or queueing a new embedding request' do
    response = create(:captain_assistant_response)
    embedding = response.reload.embedding
    updated_at = response.updated_at

    expect { described_class.perform_now }.not_to have_enqueued_job(Captain::Llm::UpdateEmbeddingJob)

    response.reload
    largest_change = response.embedding.zip(embedding).map { |new_value, old_value| (new_value - old_value).abs }.max
    expect(largest_change).to be < 1e-6
    expect(response.updated_at).to eq(updated_at)
  end
end
