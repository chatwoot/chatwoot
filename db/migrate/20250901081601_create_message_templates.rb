class CreateMessageTemplates < ActiveRecord::Migration[7.1]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :message_templates do |t|
      t.references :account, null: false
      t.references :inbox, null: true
      t.string :name, null: false, limit: 512
      t.integer :category, null: false, default: 0
      t.string :language, null: false, default: 'en', limit: 10
      t.string :channel_type, null: false, limit: 50
      t.integer :status, default: 0
      t.integer :parameter_format, null: true

      # Platform sync data
      t.string :platform_template_id, limit: 255

      # Template content
      t.jsonb :content, null: false, default: {}
      t.jsonb :metadata, default: {}

      t.references :created_by, null: true
      t.references :updated_by, null: true
      t.timestamp :last_synced_at

      t.timestamps
    end

    add_index :message_templates, :channel_type
    add_index :message_templates, :status

    add_index :message_templates, [:account_id, :name, :language, :channel_type],
              unique: true
  end
  # rubocop:enable Metrics/MethodLength
end
