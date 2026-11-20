class Migration::MoveCaptainResponseEmbeddingsInRowJob < ApplicationJob
  queue_as :async_database_migration

  # Postgres moves an existing embedding into the row only when an update writes a new copy of it.
  # Setting the column to itself keeps the old TOAST value, so each batch rebuilds the vector through a real[] round trip,
  # which copies the floats exactly. One UPDATE reads and writes the current value, so a concurrent re-embedding is not lost.
  #
  # Each run handles one batch, then schedules the next after a pause, which limits the write rate.
  # Start: Migration::MoveCaptainResponseEmbeddingsInRowJob.perform_later
  # Stop: delete the scheduled job in Sidekiq. Resume: perform_later(after_id: <last id in the logs>).
  def perform(after_id: 0, batch_size: 1_000, pause_seconds: 2)
    ids = Captain::AssistantResponse.where.not(embedding: nil).where(Captain::AssistantResponse.arel_table[:id].gt(after_id))
                                    .order(:id).limit(batch_size).pluck(:id)
    return Rails.logger.info('[MoveCaptainResponseEmbeddingsInRowJob] Finished') if ids.empty?

    move_embeddings(ids)
    Rails.logger.info("[MoveCaptainResponseEmbeddingsInRowJob] Moved #{ids.size} embeddings up to id #{ids.last}")

    self.class.set(wait: pause_seconds.seconds).perform_later(after_id: ids.last, batch_size: batch_size, pause_seconds: pause_seconds)
  end

  private

  # A column-to-column SQL update: there is nothing to validate, no callback should run, and updated_at must not change.
  def move_embeddings(ids)
    table = Captain::AssistantResponse.arel_table
    update = Arel::UpdateManager.new(table)
    update.set([[table[:embedding], fresh_copy(table[:embedding])]])
    update.where(table[:id].in(ids))
    Captain::AssistantResponse.connection.update(update, 'Move Captain response embeddings in row')
  end

  def fresh_copy(embedding)
    float_array = Arel::Nodes::NamedFunction.new('vector_to_float4', [embedding, Arel::Nodes.build_quoted(-1), Arel::Nodes.build_quoted(true)])
    Arel::Nodes::NamedFunction.new('array_to_vector', [float_array, Arel::Nodes.build_quoted(-1), Arel::Nodes.build_quoted(true)])
  end
end
