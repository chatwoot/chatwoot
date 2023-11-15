# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersAccountsInsertOrCampaignsInsert < ActiveRecord::Migration[6.0]
  def up
    create_trigger('camp_dpid_before_insert', generated: true, compatibility: 1)
      .on('accounts')
      .name('camp_dpid_before_insert')
      .after(:insert)
      .for_each(:row) do
      "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
    end

    create_trigger('campaigns_before_insert_row_tr', generated: true, compatibility: 1)
      .on('campaigns')
      .before(:insert)
      .for_each(:row) do
      "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
    end
  end

  def down
    drop_trigger('camp_dpid_before_insert', 'accounts', generated: true)

    drop_trigger('campaigns_before_insert_row_tr', 'campaigns', generated: true)
  end
end
