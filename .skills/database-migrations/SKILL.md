---
name: database-migrations
description: Create and manage database migrations in Chatwoot using Rails ActiveRecord. Use this skill when modifying database schema, adding indexes, creating new tables, or handling data migrations.
metadata:
  author: chatwoot
  version: "1.0"
---

# Database Migrations

## Creating Migrations

```bash
# Generate migration
bundle exec rails generate migration AddStatusToConversations status:integer

# Run migrations
bundle exec rails db:migrate

# Rollback last migration
bundle exec rails db:rollback

# Check migration status
bundle exec rails db:migrate:status
```

## Migration Patterns

### Create Table

```ruby
# db/migrate/xxx_create_sla_policies.rb
class CreateSlaPolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :sla_policies do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.integer :first_response_time_seconds
      t.integer :resolution_time_seconds
      t.boolean :active, default: true, null: false
      
      t.timestamps
    end

    add_index :sla_policies, [:account_id, :name], unique: true
  end
end
```

### Add Column

```ruby
class AddSlaBreachedToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :sla_breached, :boolean, default: false, null: false
    add_column :conversations, :sla_breached_at, :datetime
    
    add_index :conversations, :sla_breached, where: 'sla_breached = true'
  end
end
```

### Add Foreign Key

```ruby
class AddSlaPolicyToConversations < ActiveRecord::Migration[7.0]
  def change
    add_reference :conversations, :sla_policy, foreign_key: true, index: true
  end
end
```

### Add Index

```ruby
class AddIndexToMessages < ActiveRecord::Migration[7.0]
  def change
    # Simple index
    add_index :messages, :conversation_id
    
    # Composite index
    add_index :messages, [:conversation_id, :created_at]
    
    # Unique index
    add_index :messages, :source_id, unique: true
    
    # Partial index
    add_index :messages, :sender_id, where: "sender_type = 'User'"
    
    # Concurrent index (for large tables)
    add_index :messages, :content, algorithm: :concurrently
  end
end
```

### JSONB Column

```ruby
class AddAdditionalAttributesToContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :contacts, :additional_attributes, :jsonb, default: {}
    
    # Add GIN index for JSONB queries
    add_index :contacts, :additional_attributes, using: :gin
  end
end
```

### Enum Column

```ruby
class AddStatusToConversations < ActiveRecord::Migration[7.0]
  def change
    # Integer enum (preferred for Rails enums)
    add_column :conversations, :priority, :integer, default: 0, null: false
    
    add_index :conversations, :priority
  end
end

# In model:
# enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }
```

## Data Migrations

For data changes, use separate data migration files:

```ruby
# db/migrate/xxx_backfill_conversation_sla_status.rb
class BackfillConversationSlaStatus < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Conversation.in_batches(of: 1000) do |batch|
      batch.update_all(sla_breached: false)
    end
  end

  def down
    # Reversible if needed
  end
end
```

### Safe Data Migration Pattern

```ruby
class MigrateConversationStatus < ActiveRecord::Migration[7.0]
  def up
    # Add new column first
    add_column :conversations, :new_status, :integer

    # Migrate data in batches
    say_with_time 'Migrating conversation statuses' do
      Conversation.find_each do |conv|
        new_status = map_status(conv.old_status)
        conv.update_column(:new_status, new_status)
      end
    end

    # Remove old column
    remove_column :conversations, :old_status
    
    # Rename new column
    rename_column :conversations, :new_status, :status
  end

  private

  def map_status(old_status)
    case old_status
    when 'active' then 0
    when 'closed' then 1
    else 0
    end
  end
end
```

## Best Practices

### Always Add Indexes

```ruby
# ✅ Good - index on foreign key
add_reference :messages, :conversation, foreign_key: true, index: true

# ✅ Good - index on frequently queried columns
add_index :conversations, [:account_id, :status]
add_index :messages, :created_at

# ❌ Bad - missing index on foreign key
add_column :messages, :conversation_id, :integer
```

### Use Null Constraints

```ruby
# ✅ Good
add_column :users, :email, :string, null: false
add_column :conversations, :status, :integer, default: 0, null: false

# ❌ Bad - allows nulls when it shouldn't
add_column :users, :email, :string
```

### Reversible Migrations

```ruby
class AddColumnWithDefault < ActiveRecord::Migration[7.0]
  def change
    # Automatically reversible
    add_column :users, :role, :string, default: 'agent'
  end
end

# For complex migrations, use up/down
class ComplexMigration < ActiveRecord::Migration[7.0]
  def up
    # Forward migration
  end

  def down
    # Reverse migration
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Large Table Migrations

For tables with millions of rows:

```ruby
class AddIndexToLargeTable < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # Use CONCURRENTLY to avoid locking
    add_index :messages, :source_id, algorithm: :concurrently
  end
end
```

### Column Type Changes

```ruby
class ChangeColumnType < ActiveRecord::Migration[7.0]
  def up
    # Add new column
    add_column :table, :new_column, :bigint

    # Copy data
    execute "UPDATE table SET new_column = old_column"

    # Remove old, rename new
    remove_column :table, :old_column
    rename_column :table, :new_column, :column_name
  end

  def down
    # Reverse the process
  end
end
```

## Enterprise Migrations

Place Enterprise-specific migrations in `enterprise/db/migrate/`:

```ruby
# enterprise/db/migrate/xxx_create_enterprise_feature.rb
class CreateEnterpriseFeature < ActiveRecord::Migration[7.0]
  def change
    create_table :enterprise_features do |t|
      t.references :account, null: false, foreign_key: true
      t.string :feature_name
      t.timestamps
    end
  end
end
```

## Schema Reference

The current schema is in `db/schema.rb`. Always check it before creating migrations to avoid conflicts.

## Troubleshooting

### Migration Failed

```bash
# Check status
bundle exec rails db:migrate:status

# Rollback failed migration
bundle exec rails db:rollback

# Fix and re-run
bundle exec rails db:migrate
```

### Pending Migrations in Test

```bash
RAILS_ENV=test bundle exec rails db:migrate
```
