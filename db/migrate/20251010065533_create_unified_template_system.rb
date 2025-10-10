# frozen_string_literal: true

class CreateUnifiedTemplateSystem < ActiveRecord::Migration[7.0]
  def change
    # Main template storage
    create_table :message_templates do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :category
      t.text :description

      # Parameter definitions for bots
      t.jsonb :parameters, default: {}

      # Channel compatibility
      t.text :supported_channels, array: true, default: []

      # Template status and versioning
      t.string :status, default: 'active'
      t.integer :version, default: 1

      # Bot integration metadata
      t.text :tags, array: true, default: []
      t.text :use_cases, array: true, default: []

      t.timestamps
    end

    # Template content blocks for reusability
    create_table :template_content_blocks do |t|
      t.bigint :message_template_id, null: false
      t.string :block_type, null: false
      t.jsonb :properties, default: {}
      t.jsonb :conditions, default: {}
      t.integer :order_index, null: false, default: 0

      t.timestamps
    end

    # Channel-specific adaptations
    create_table :template_channel_mappings do |t|
      t.bigint :message_template_id, null: false
      t.string :channel_type, null: false
      t.string :content_type
      t.jsonb :field_mappings, default: {}

      t.timestamps
    end

    # Template usage analytics for bots
    create_table :template_usage_logs do |t|
      t.bigint :message_template_id, null: false
      t.bigint :account_id, null: false
      t.bigint :conversation_id
      t.string :sender_type
      t.bigint :sender_id
      t.jsonb :parameters_used, default: {}
      t.string :channel_type
      t.boolean :success, default: true, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :message_templates, :account_id
    add_index :message_templates, :category
    add_index :message_templates, :status
    add_index :message_templates, :tags, using: :gin
    add_index :message_templates, :supported_channels, using: :gin
    add_index :message_templates, [:account_id, :category]
    add_index :message_templates, [:account_id, :status]

    add_index :template_content_blocks, :message_template_id
    add_index :template_content_blocks, :block_type
    add_index :template_content_blocks, [:message_template_id, :order_index],
              name: 'index_content_blocks_on_template_and_order'

    add_index :template_channel_mappings, :message_template_id
    add_index :template_channel_mappings, :channel_type
    add_index :template_channel_mappings, [:message_template_id, :channel_type], unique: true,
                                                                                 name: 'index_channel_mappings_on_template_and_channel'

    add_index :template_usage_logs, :message_template_id
    add_index :template_usage_logs, :account_id
    add_index :template_usage_logs, :conversation_id
    add_index :template_usage_logs, :channel_type
    add_index :template_usage_logs, :created_at
    add_index :template_usage_logs, [:message_template_id, :success]
    add_index :template_usage_logs, [:account_id, :created_at]

    # Add foreign keys
    add_foreign_key :message_templates, :accounts, on_delete: :cascade
    add_foreign_key :template_content_blocks, :message_templates, on_delete: :cascade
    add_foreign_key :template_channel_mappings, :message_templates, on_delete: :cascade
    add_foreign_key :template_usage_logs, :message_templates, on_delete: :cascade
    add_foreign_key :template_usage_logs, :accounts, on_delete: :cascade
    add_foreign_key :template_usage_logs, :conversations, on_delete: :cascade
  end
end
