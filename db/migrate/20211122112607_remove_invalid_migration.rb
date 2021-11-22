class RemoveInvalidMigration < ActiveRecord::Migration[6.1]
  def change
    drop_table :actions if ActiveRecord::Base.connection.table_exists? 'actions'
  end
end
