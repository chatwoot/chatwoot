class EnqueueCaptainKnowledgeMapBackfill < ActiveRecord::Migration[7.1]
  def up
    return unless ChatwootApp.enterprise?

    Migration::BackfillCaptainKnowledgeMapsJob.perform_later
  end

  def down; end
end
