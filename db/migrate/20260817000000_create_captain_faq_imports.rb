class CreateCaptainFaqImports < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_faq_imports do |t|
      add_owner_columns(t)
      add_import_columns(t)
      add_counter_columns(t)
      add_completion_columns(t)
      t.timestamps
    end

    add_index :captain_faq_imports,
              :assistant_id,
              unique: true,
              where: 'status IN (0, 1)',
              name: 'idx_captain_faq_imports_one_active_per_assistant'
  end

  private

  def add_owner_columns(table)
    table.references :account, null: false, foreign_key: true
    table.references :assistant, null: false, foreign_key: { to_table: :captain_assistants }
    table.references :user, null: true, foreign_key: { on_delete: :nullify }
  end

  def add_import_columns(table)
    table.string :original_filename, null: false
    table.string :checksum, null: false
    table.integer :status, null: false, default: 0
    table.jsonb :rows, null: false, default: []
  end

  def add_counter_columns(table)
    table.integer :row_count, null: false, default: 0
    table.integer :created_count, null: false, default: 0
    table.integer :overwritten_count, null: false, default: 0
    table.integer :skipped_count, null: false, default: 0
    table.integer :embedding_ready_count, null: false, default: 0
    table.integer :embedding_failed_count, null: false, default: 0
  end

  def add_completion_columns(table)
    table.text :error_message
    table.datetime :confirmed_at
    table.datetime :completed_at
  end
end
