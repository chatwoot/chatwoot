class AddAssigneeIdToContacts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change # rubocop:disable Metrics/MethodLength
    # Increase timeout for this migration (in milliseconds)
    # 1 hour = 3600000ms, adjust based on your table size
    execute "SET statement_timeout = '3600000'" # 1 hour # rubocop:disable Rails/ReversibleMigration

    # Step 1: Add column only if it doesn't exist
    add_column :contacts, :assignee_id, :bigint unless column_exists?(:contacts, :assignee_id)

    # Step 2: Add indexes concurrently
    unless index_exists?(:contacts, [:account_id, :assignee_id], name: :index_contacts_on_account_id_and_assignee_id)
      add_index :contacts,
                [:account_id, :assignee_id],
                algorithm: :concurrently,
                name: :index_contacts_on_account_id_and_assignee_id
    end

    unless index_exists?(:contacts, [:assignee_id, :last_activity_at], name: :index_contacts_on_assignee_id_and_last_activity_at)
      add_index :contacts,
                [:assignee_id, :last_activity_at],
                algorithm: :concurrently,
                name: :index_contacts_on_assignee_id_and_last_activity_at
    end

    # Step 3: Add foreign key if it doesn't exist
    unless foreign_key_exists?(:contacts, :users, column: :assignee_id)
      add_foreign_key :contacts, :users, column: :assignee_id, validate: false
      validate_foreign_key :contacts, :users, column: :assignee_id
    end
  ensure
    # Reset timeout back to default
    execute 'SET statement_timeout = DEFAULT' # rubocop:disable Rails/ReversibleMigration
  end
end
