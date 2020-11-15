class ConversationTrigger < ActiveRecord::Migration[6.0]
  def up
    connection.execute(%q(
    CREATE FUNCTION make_account_seq() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    begin
    execute format('create sequence account_seq_%s', NEW.id);
    return NEW;
    end
    $$;

    CREATE TRIGGER make_account_seq AFTER INSERT ON accounts FOR EACH ROW EXECUTE PROCEDURE make_account_seq();

    CREATE FUNCTION fill_conv_seq() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    begin
    NEW.display_id := nextval('account_seq_' || NEW.account_id);
    RETURN NEW;
    end
    $$;

    CREATE TRIGGER fill_conv_seq BEFORE INSERT ON conversations FOR EACH ROW EXECUTE PROCEDURE fill_conv_seq();

    ))
  end

  def down
    connection.execute(%q(
    DROP FUNCTION IF EXISTS fill_conv_seq() cascade;
    DROP FUNCTION IF EXISTS make_account_seq() cascade;
                       ))
  end
end
