class RemoveRobinTables < ActiveRecord::Migration[7.0]
  def change
    # rubocop:disable Rails/ReversibleMigration
    drop_table :responses if table_exists?(:responses)
    drop_table :response_sources if table_exists?(:response_sources)
    drop_table :response_documents if table_exists?(:response_documents)
    drop_table :inbox_response_sources if table_exists?(:inbox_response_sources)
    # rubocop:enable Rails/ReversibleMigration
  end
end
