module HairTrigger
  module Adapter
    def create_trigger(name = nil, options = {})
      if name.is_a?(Hash)
        options = name
        name = nil
      end
      ::HairTrigger::Builder.new(name, options.merge(:execute => true, :adapter => self))
    end

    def drop_trigger(name, table, options = {})
      ::HairTrigger::Builder.new(name, options.merge(:execute => true, :drop => true, :table => table, :adapter => self)).all{}
    end

    def normalize_mysql_definer(definer)
      user, host = definer.split('@')
      host = @config[:host] || 'localhost' if host == '%'
      "'#{user}'@'#{host}'" # SHOW TRIGGERS doesn't quote them, but we need quotes for creating a trigger
    end

    def implicit_mysql_definer
      "'#{@config[:username] || 'root'}'@'#{@config[:host] || 'localhost'}'"
    end

    def triggers(options = {})
      triggers = {}
      name_clause = options[:only] ? "IN ('" + options[:only].join("', '") + "')" : nil
      adapter_name = HairTrigger.adapter_name_for(self)
      case adapter_name
        when :sqlite
          select_rows("SELECT name, sql FROM sqlite_master WHERE type = 'trigger' #{name_clause ? " AND name " + name_clause : ""}").each do |(name, definition)|
            triggers[name] = quote_table_name_in_trigger(definition) + ";\n"
          end
        when :mysql
          select_rows("SHOW TRIGGERS").each do |(name, event, table, actions, timing, created, sql_mode, definer)|
            definer = normalize_mysql_definer(definer)
            next if options[:only] && !options[:only].include?(name)
            triggers[name.strip] = <<-SQL
CREATE #{definer != implicit_mysql_definer ? "DEFINER = #{definer} " : ""}TRIGGER #{name} #{timing} #{event} ON `#{table}`
FOR EACH ROW
#{actions}
            SQL
          end
        when :postgresql, :postgis
          function_conditions = "(SELECT typname FROM pg_type WHERE oid = prorettype) = 'trigger'"
          function_conditions << <<-SQL unless options[:simple_check]
            AND oid IN (
              SELECT tgfoid
              FROM pg_trigger
              WHERE NOT tgisinternal AND tgconstrrelid = 0 AND tgrelid IN (
                SELECT oid FROM pg_class WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
              )
            )
          SQL

          sql = <<-SQL
            SELECT tgname::varchar, pg_get_triggerdef(oid, true)
            FROM pg_trigger
            WHERE NOT tgisinternal AND tgconstrrelid = 0 AND tgrelid IN (
              SELECT oid FROM pg_class WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
            )
            
            #{name_clause ? " AND tgname::varchar " + name_clause : ""}
            UNION
            SELECT proname || '()', pg_get_functiondef(oid)
            FROM pg_proc
            WHERE #{function_conditions}
              #{name_clause ? " AND (proname || '()')::varchar " + name_clause : ""}
          SQL
          select_rows(sql).each do |(name, definition)|
            triggers[name] = quote_table_name_in_trigger(definition)
          end
        else
          raise "don't know how to retrieve #{adapter_name} triggers yet"
      end
      triggers
    end

    # a bit hacky, but we need to ensure the table name is always quoted
    # on the way out, not just for reserved words. this is because we
    # always quote on the way in, so we need them to match exactly
    # when diffing
    def quote_table_name_in_trigger(definition)
      pattern = /
        (
          CREATE\sTRIGGER\s+
          \S+\s+
          (BEFORE|AFTER|INSTEAD\s+OF)\s+
          (INSERT|UPDATE|DELETE|TRUNCATE)\s+
          (OR\s+(INSERT|UPDATE|DELETE|TRUNCATE)\s+)*
          (ON\s+)
        )
        (\w+) # quote if not already quoted
      /ixm
      definition.sub(pattern, '\\1"\\7"')
    end
  end
end
