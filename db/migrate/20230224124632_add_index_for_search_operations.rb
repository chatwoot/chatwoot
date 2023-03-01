class AddIndexForSearchOperations < ActiveRecord::Migration[6.1]
  def change
    enable_extension('pg_trgm')
    Migration::AddSearchIndexesJob.perform_later
  end
end
