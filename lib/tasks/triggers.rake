# Chatwoot derives a conversation/campaign's display_id from a database
# trigger that owns a per-account sequence (conv_dpid_seq_<account_id> /
# camp_dpid_seq_<account_id>). Rails' schema.rb cannot represent database
# triggers, so a schema loaded from schema.rb (which is what `db:prepare` does
# for a freshly created database) never contains these triggers. A one-time
# migration cannot be relied on either, because after a schema reload the
# migration is already recorded as applied and is skipped, leaving the triggers
# absent and every conversation/campaign insert failing with a NOT NULL
# violation on display_id.
#
# This task recreates the triggers idempotently so it is safe to run on every
# boot and after any schema load. It also backfills the per-account sequences
# for accounts that already exist so the next nextval() does not collide with
# rows already in the table.
namespace :db do
  desc 'Ensure the display_id database triggers (and per-account sequences) exist'
  task ensure_triggers: :environment do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION create_conv_dpid_seq() RETURNS trigger AS $$
      BEGIN
        EXECUTE format('CREATE SEQUENCE IF NOT EXISTS conv_dpid_seq_%s', NEW.id);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION set_conv_display_id() RETURNS trigger AS $$
      BEGIN
        NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION create_camp_dpid_seq() RETURNS trigger AS $$
      BEGIN
        EXECUTE format('CREATE SEQUENCE IF NOT EXISTS camp_dpid_seq_%s', NEW.id);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION set_camp_display_id() RETURNS trigger AS $$
      BEGIN
        NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS accounts_after_insert_row_tr ON accounts;
      CREATE TRIGGER accounts_after_insert_row_tr
        AFTER INSERT ON accounts
        FOR EACH ROW EXECUTE FUNCTION create_conv_dpid_seq();

      DROP TRIGGER IF EXISTS conversations_before_insert_row_tr ON conversations;
      CREATE TRIGGER conversations_before_insert_row_tr
        BEFORE INSERT ON conversations
        FOR EACH ROW EXECUTE FUNCTION set_conv_display_id();

      DROP TRIGGER IF EXISTS camp_dpid_before_insert ON accounts;
      CREATE TRIGGER camp_dpid_before_insert
        AFTER INSERT ON accounts
        FOR EACH ROW EXECUTE FUNCTION create_camp_dpid_seq();

      DROP TRIGGER IF EXISTS campaigns_before_insert_row_tr ON campaigns;
      CREATE TRIGGER campaigns_before_insert_row_tr
        BEFORE INSERT ON campaigns
        FOR EACH ROW EXECUTE FUNCTION set_camp_display_id();
    SQL

    account_ids = ActiveRecord::Base.connection.select_values('SELECT id FROM accounts')
    account_ids.each do |account_id|
      max_conv = ActiveRecord::Base.connection.select_value(
        "SELECT COALESCE(MAX(display_id), 0) FROM conversations WHERE account_id = #{account_id}"
      ).to_i
      ActiveRecord::Base.connection.execute(
        "CREATE SEQUENCE IF NOT EXISTS conv_dpid_seq_#{account_id} START WITH #{max_conv + 1}"
      )

      max_camp = ActiveRecord::Base.connection.select_value(
        "SELECT COALESCE(MAX(display_id), 0) FROM campaigns WHERE account_id = #{account_id}"
      ).to_i
      ActiveRecord::Base.connection.execute(
        "CREATE SEQUENCE IF NOT EXISTS camp_dpid_seq_#{account_id} START WITH #{max_camp + 1}"
      )
    end

    puts 'Ensured display_id triggers and per-account sequences exist.'
  end
end
