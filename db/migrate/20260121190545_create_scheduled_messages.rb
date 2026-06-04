class CreateScheduledMessages < ActiveRecord::Migration[7.1]
  # Columns (name => cast type) the fazer-ai fork table has had since creation.
  # They act as a fingerprint to tell our table apart from a scheduled_messages
  # coming from another Chatwoot version/fork, whose schema we don't know up
  # front. Nullability is intentionally not matched: 20260201162122 relaxes
  # author_id/author_type to nullable, so it varies across fork schema stages.
  # The PostgreSQL adapter reports bigint columns as :integer.
  FORK_SIGNATURE_COLUMNS = {
    'id' => :integer,
    'content' => :text,
    'template_params' => :jsonb,
    'scheduled_at' => :datetime,
    'status' => :integer,
    'account_id' => :integer,
    'conversation_id' => :integer,
    'inbox_id' => :integer,
    'author_type' => :string,
    'author_id' => :integer,
    'message_id' => :integer,
    'created_at' => :datetime,
    'updated_at' => :datetime
  }.freeze

  def up
    relocate_conflicting_table if table_exists?(:scheduled_messages)

    create_table :scheduled_messages do |t|
      t.text :content
      t.jsonb :template_params, default: {}
      t.datetime :scheduled_at
      t.integer :status, default: 0, null: false

      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true

      t.references :author, null: false, polymorphic: true
      t.references :message, null: true, foreign_key: true

      t.timestamps
    end

    add_scheduled_messages_indexes
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'CreateScheduledMessages cannot be rolled back: up may relocate an imported ' \
          'scheduled_messages table or be stamped manually, so dropping the table here ' \
          'could destroy pre-existing data.'
  end

  private

  def relocate_conflicting_table
    if fork_table?
      raise ActiveRecord::MigrationError, <<~MSG.squish
        scheduled_messages already exists with the fazer-ai fork schema, but migration
        20260121190545 is missing from schema_migrations. This is an inconsistent
        database (partial restore / out-of-sync schema_migrations), not a migration
        from another Chatwoot version. Register the version manually
        (INSERT INTO schema_migrations (version) VALUES ('20260121190545');) and review
        the rest of the scheduled_messages migration family before re-running.
      MSG
    end

    # Unknown schema from another version: move the whole table (with indexes,
    # sequences and constraints) out of `public`, preserving the data and freeing
    # the name plus every associated object name.
    target = "scheduled_messages_#{Time.now.utc.to_i}"
    execute('CREATE SCHEMA IF NOT EXISTS chatwoot_legacy')
    execute('ALTER TABLE scheduled_messages SET SCHEMA chatwoot_legacy')
    execute("ALTER TABLE chatwoot_legacy.scheduled_messages RENAME TO #{target}")
    say "scheduled_messages from another version preserved at chatwoot_legacy.#{target}"
  end

  def fork_table?
    columns = connection.columns(:scheduled_messages).index_by(&:name)
    FORK_SIGNATURE_COLUMNS.all? do |name, type|
      column = columns[name]
      column && column.type == type
    end
  end

  def add_scheduled_messages_indexes
    add_index :scheduled_messages, [:account_id, :status]
    add_index :scheduled_messages, [:conversation_id, :status]
    add_index :scheduled_messages, [:conversation_id, :scheduled_at]
    add_index :scheduled_messages, [:status, :scheduled_at]
    add_index :scheduled_messages, [:author_type, :author_id, :status]
    add_index :scheduled_messages, [:inbox_id, :status]
  end
end
