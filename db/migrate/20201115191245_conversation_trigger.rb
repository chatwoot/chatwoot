class ConversationTrigger < ActiveRecord::Migration[6.0]
  def up
    connection.execute("
    CREATE OR REPLACE FUNCTION make_account_seq() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    begin
    execute format('create sequence account_seq_%s', NEW.id);
    return NEW;
    end
    $$;

    DROP TRIGGER IF EXISTS make_account_seq ON accounts;
    CREATE TRIGGER make_account_seq AFTER INSERT ON accounts FOR EACH ROW EXECUTE PROCEDURE make_account_seq();

    CREATE OR REPLACE FUNCTION fill_conv_seq() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    begin
    NEW.display_id := nextval('account_seq_' || NEW.account_id);
    RETURN NEW;
    end
    $$;

    DROP TRIGGER IF EXISTS fill_conv_seq ON conversations;
    CREATE TRIGGER fill_conv_seq BEFORE INSERT ON conversations FOR EACH ROW EXECUTE PROCEDURE fill_conv_seq();

    ")
  end

  def down
    connection.execute('
    DROP FUNCTION IF EXISTS fill_conv_seq() cascade;
    DROP FUNCTION IF EXISTS make_account_seq() cascade;
                       ')
  end
end
