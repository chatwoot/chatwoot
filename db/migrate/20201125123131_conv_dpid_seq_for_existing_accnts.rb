class ConvDpidSeqForExistingAccnts < ActiveRecord::Migration[6.0]
  def up # rubocop:disable Metrics/MethodLength
    connection.execute("
    do $$
    declare
       disp_id_start integer;
       max_accnt_id integer;
       curr_accnt_id integer := 0 ;
    begin
        execute 'select MAX(id) from accounts' into max_accnt_id;
        IF max_accnt_id IS NOT NULL then
            loop
                exit when curr_accnt_id > max_accnt_id-1 ;
                curr_accnt_id := curr_accnt_id + 1 ;
                execute format('select MAX(display_id) from conversations where account_id=%s', curr_accnt_id) into disp_id_start;
                IF disp_id_start IS NULL then
                    disp_id_start := 0;
                END IF;
                execute 'create sequence IF NOT EXISTS conv_dpid_seq_' || curr_accnt_id || ' START ' || disp_id_start+1;
            end loop;
        END IF;
        raise notice '%', curr_accnt_id;
    end; $$;
    ")
  end

  def down
    connection.execute("
    do $$
    declare
        max_accnt_id integer;
        curr_accnt_id integer := 0 ;
    begin
        execute 'select MAX(id) from accounts' into max_accnt_id;
        IF max_accnt_id IS NOT NULL then
            loop
                exit when curr_accnt_id > max_accnt_id-1 ;
                curr_accnt_id := curr_accnt_id + 1 ;
                execute 'drop sequence IF EXISTS conv_dpid_seq_' || curr_accnt_id ;
            end loop;
        END IF;
        raise notice '%', curr_accnt_id;
    end; $$;
    ")
  end
end
