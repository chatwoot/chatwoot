class AddTimelineMetadataToNotes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    add_column :notes, :updated_by_id, :bigint
    add_column :notes, :source, :string, null: false, default: 'manual'
    add_column :notes, :metadata, :jsonb, null: false, default: {}

    add_index :notes, :updated_by_id, algorithm: :concurrently
    add_index :notes, [:contact_id, :created_at, :id], name: 'index_notes_on_contact_timeline', algorithm: :concurrently
    add_foreign_key :notes, :users, column: :updated_by_id, validate: false

    backfill_updated_by_id
    validate_foreign_key :notes, :users, column: :updated_by_id
  end

  def down
    remove_foreign_key :notes, column: :updated_by_id if foreign_key_exists?(:notes, :users, column: :updated_by_id)
    remove_index :notes, column: :updated_by_id, algorithm: :concurrently if index_exists?(:notes, :updated_by_id)
    if index_exists?(:notes, [:contact_id, :created_at, :id], name: 'index_notes_on_contact_timeline')
      remove_index :notes, name: 'index_notes_on_contact_timeline', algorithm: :concurrently
    end
    remove_column :notes, :metadata if column_exists?(:notes, :metadata)
    remove_column :notes, :source if column_exists?(:notes, :source)
    remove_column :notes, :updated_by_id if column_exists?(:notes, :updated_by_id)
  end

  private

  def backfill_updated_by_id
    last_id = 0

    loop do
      note_ids = next_note_ids(last_id)
      break if note_ids.empty?

      last_id = note_ids.last.to_i
      backfill_updated_by_id_range(note_ids.first.to_i, last_id)
    end
  end

  def next_note_ids(last_id)
    select_values(<<~SQL.squish)
      SELECT notes.id
      FROM notes
      INNER JOIN users ON users.id = notes.user_id
      WHERE notes.updated_by_id IS NULL
        AND notes.id > #{last_id}
      ORDER BY notes.id ASC
      LIMIT #{BATCH_SIZE}
    SQL
  end

  def backfill_updated_by_id_range(first_id, last_id)
    execute <<~SQL.squish
      UPDATE notes
      SET updated_by_id = users.id
      FROM users
      WHERE notes.updated_by_id IS NULL
        AND notes.user_id = users.id
        AND notes.id BETWEEN #{first_id} AND #{last_id}
    SQL
  end
end
