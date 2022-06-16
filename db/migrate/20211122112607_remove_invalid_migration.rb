class RemoveInvalidMigration < ActiveRecord::Migration[6.1]
  def change
    return unless ActiveRecord::Base.connection.table_exists? 'actions'

    drop_table :actions do |t|
      t.string :name
      t.jsonb :execution_list
      t.datetime :created_at
      t.datetime :updated_at
      t.index ['name'], name: 'index_actions_on_name'
    end
  end
end
