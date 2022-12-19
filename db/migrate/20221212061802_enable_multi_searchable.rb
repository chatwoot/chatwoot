class EnableMultiSearchable < ActiveRecord::Migration[6.1]
  def up
    ::Conversations::MultiSearchJob.perform_now
    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
  end

  def down
    PgSearch::Document.delete_all
  end
end
