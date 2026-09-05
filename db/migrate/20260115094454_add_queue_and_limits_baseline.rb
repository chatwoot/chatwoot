# rubocop:disable Metrics/MethodLength, Metrics/AbcSize,
# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

# NOTE: Baseline schema migration.
# This migration establishes the initial queue/limits schema.
# Data backfills (e.g. inbox_id population) are intentionally excluded.
class AddQueueAndLimitsBaseline < ActiveRecord::Migration[7.1]
  def up
    # accounts
    unless column_exists?(:accounts, :active_chat_limit_enabled)
      add_column :accounts, :active_chat_limit_enabled, :boolean, default: false, null: false
    end

    add_column :accounts, :active_chat_limit_value, :integer, default: 7 unless column_exists?(:accounts, :active_chat_limit_value)

    add_column :accounts, :queue_enabled, :boolean, default: false, null: false unless column_exists?(:accounts, :queue_enabled)

    add_column :accounts, :queue_message, :text unless column_exists?(:accounts, :queue_message)

    # account_users
    add_column :account_users, :active_chat_limit, :integer unless column_exists?(:account_users, :active_chat_limit)

    unless column_exists?(:account_users, :active_chat_limit_enabled)
      add_column :account_users, :active_chat_limit_enabled, :boolean, default: false, null: false
    end

    # conversation_queues
    unless table_exists?(:conversation_queues)
      create_table :conversation_queues do |t|
        t.bigint :conversation_id, null: false
        t.bigint :account_id, null: false
        t.bigint :inbox_id

        t.datetime :queued_at, null: false
        t.datetime :assigned_at
        t.datetime :left_at

        t.integer :position, null: false
        t.integer :status, default: 0, null: false

        t.timestamps
      end
    end

    add_index :conversation_queues, :conversation_id, unique: true unless index_exists?(:conversation_queues, :conversation_id, unique: true)

    add_index :conversation_queues, [:account_id, :status, :position] unless index_exists?(:conversation_queues, [:account_id, :status, :position])

    add_index :conversation_queues, [:account_id, :status, :queued_at] unless index_exists?(:conversation_queues, [:account_id, :status, :queued_at])

    add_foreign_key :conversation_queues, :conversations unless foreign_key_exists?(:conversation_queues, :conversations)

    add_foreign_key :conversation_queues, :accounts unless foreign_key_exists?(:conversation_queues, :accounts)

    add_foreign_key :conversation_queues, :inboxes unless foreign_key_exists?(:conversation_queues, :inboxes)

    # queue_statistics
    unless table_exists?(:queue_statistics)
      create_table :queue_statistics do |t|
        t.bigint :account_id, null: false
        t.date :date, null: false

        t.integer :total_queued, default: 0, null: false
        t.integer :total_assigned, default: 0, null: false
        t.integer :total_left, default: 0, null: false
        t.integer :average_wait_time_seconds, default: 0, null: false
        t.integer :max_wait_time_seconds, default: 0, null: false

        t.timestamps
      end
    end

    add_index :queue_statistics, [:account_id, :date], unique: true unless index_exists?(:queue_statistics, [:account_id, :date], unique: true)

    add_foreign_key :queue_statistics, :accounts unless foreign_key_exists?(:queue_statistics, :accounts)

    # priority_groups
    unless table_exists?(:priority_groups)
      create_table :priority_groups do |t|
        t.string :name, null: false
        t.bigint :account_id, null: false

        t.timestamps
      end
    end

    add_index :priority_groups, [:account_id, :name], unique: true unless index_exists?(:priority_groups, [:account_id, :name], unique: true)

    add_foreign_key :priority_groups, :accounts unless foreign_key_exists?(:priority_groups, :accounts)

    # inboxes.priority_group_id
    add_column :inboxes, :priority_group_id, :bigint unless column_exists?(:inboxes, :priority_group_id)

    add_index :inboxes, :priority_group_id unless index_exists?(:inboxes, :priority_group_id)

    return if foreign_key_exists?(:inboxes, :priority_groups)

    add_foreign_key :inboxes, :priority_groups
  end

  # NOTE: Guarded rollback for baseline migration.
  # This rollback is schema-based, not historical.
  # It removes all objects introduced by this migration if they exist.
  def down
    # inboxes
    remove_foreign_key :inboxes, :priority_groups if foreign_key_exists?(:inboxes, :priority_groups)

    remove_index :inboxes, :priority_group_id if index_exists?(:inboxes, :priority_group_id)

    remove_column :inboxes, :priority_group_id if column_exists?(:inboxes, :priority_group_id)

    # priority_groups
    remove_foreign_key :priority_groups, :accounts if foreign_key_exists?(:priority_groups, :accounts)

    remove_index :priority_groups, column: [:account_id, :name] if index_exists?(:priority_groups, [:account_id, :name])

    drop_table :priority_groups, if_exists: true

    # queue_statistics
    remove_foreign_key :queue_statistics, :accounts if foreign_key_exists?(:queue_statistics, :accounts)

    remove_index :queue_statistics, column: [:account_id, :date] if index_exists?(:queue_statistics, [:account_id, :date])

    drop_table :queue_statistics, if_exists: true

    # conversation_queues
    remove_foreign_key :conversation_queues, :inboxes if foreign_key_exists?(:conversation_queues, :inboxes)

    remove_foreign_key :conversation_queues, :accounts if foreign_key_exists?(:conversation_queues, :accounts)

    remove_foreign_key :conversation_queues, :conversations if foreign_key_exists?(:conversation_queues, :conversations)

    remove_index :conversation_queues, :conversation_id if index_exists?(:conversation_queues, :conversation_id)

    if index_exists?(:conversation_queues, [:account_id, :status, :position])
      remove_index :conversation_queues, column: [:account_id, :status, :position]
    end

    if index_exists?(:conversation_queues, [:account_id, :status, :queued_at])
      remove_index :conversation_queues, column: [:account_id, :status, :queued_at]
    end

    drop_table :conversation_queues, if_exists: true

    # account_users
    remove_column :account_users, :active_chat_limit_enabled if column_exists?(:account_users, :active_chat_limit_enabled)

    remove_column :account_users, :active_chat_limit if column_exists?(:account_users, :active_chat_limit)

    # accounts
    remove_column :accounts, :queue_message if column_exists?(:accounts, :queue_message)

    remove_column :accounts, :queue_enabled if column_exists?(:accounts, :queue_enabled)

    remove_column :accounts, :active_chat_limit_value if column_exists?(:accounts, :active_chat_limit_value)

    return unless column_exists?(:accounts, :active_chat_limit_enabled)

    remove_column :accounts, :active_chat_limit_enabled
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize,
# rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
