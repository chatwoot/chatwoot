class Migration::MoveCaptainResponseEmbeddingsInRowJob < ApplicationJob
  queue_as :async_database_migration

  # Postgres moves an existing embedding into the row only when an update sends a new copy of it.
  # A SQL update that sets the column to itself keeps the old TOAST value, so this writes each embedding back from Ruby.
  # Safe to stop and run again: rewriting a row that is already stored in the row is harmless.
  def perform
    Rails.logger.info('[MoveCaptainResponseEmbeddingsInRowJob] Started')
    moved = 0

    Captain::AssistantResponse.where.not(embedding: nil).find_each(batch_size: 500) do |response|
      # Marking the embedding as changed makes the save send it again. has_neighbors normalizes it on write, which can
      # change the last float digit (under 1e-8) but not search results. Validations are skipped because only the
      # embedding is written. touch: false keeps updated_at, and the after_commit embedding refresh does not run
      # because question and answer are unchanged and the embedding is present.
      response.embedding_will_change!
      response.save!(validate: false, touch: false)
      moved += 1
    end

    Rails.logger.info("[MoveCaptainResponseEmbeddingsInRowJob] Rewrote #{moved} embeddings")
  end
end
