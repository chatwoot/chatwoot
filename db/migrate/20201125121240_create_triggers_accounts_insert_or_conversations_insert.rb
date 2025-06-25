# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersAccountsInsertOrConversationsInsert < ActiveRecord::Migration[6.0]
  def up
    create_trigger('accounts_after_insert_row_tr', generated: true, compatibility: 1)
      .on('accounts')
      .after(:insert)
      .for_each(:row) do
      "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
    end

    create_trigger('conversations_before_insert_row_tr', generated: true, compatibility: 1)
      .on('conversations')
      .before(:insert)
      .for_each(:row) do
      "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
    end
  end

  def down
    drop_trigger('accounts_after_insert_row_tr', 'accounts', generated: true)

    drop_trigger('conversations_before_insert_row_tr', 'conversations', generated: true)
  end
end
