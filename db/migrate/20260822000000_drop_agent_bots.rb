class DropAgentBots < ActiveRecord::Migration[7.2]
  def up
    drop_table :agent_bot_inboxes, if_exists: true
    drop_table :agent_bots, if_exists: true
    remove_column :conversations, :assignee_agent_bot_id if column_exists?(:conversations, :assignee_agent_bot_id)
  end

  def down
    create_table :agent_bot_inboxes do |t|
      t.integer :inbox_id
      t.integer :agent_bot_id
      t.integer :status, default: 0
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :account_id
    end

    create_table :agent_bots do |t|
      t.string :name
      t.string :description
      t.string :outgoing_url
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.bigint :account_id
      t.integer :bot_type, default: 0
      t.jsonb :bot_config, default: {}
      t.string :secret
      t.index [:account_id], name: 'index_agent_bots_on_account_id'
    end

    add_column :conversations, :assignee_agent_bot_id, :bigint if !column_exists?(:conversations, :assignee_agent_bot_id)
  end
end
