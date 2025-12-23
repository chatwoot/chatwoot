module HairTrigger
  module SchemaDumper
    module Configuration
      mattr_accessor :allow_tables
      mattr_accessor :allow_triggers
      mattr_accessor :ignore_tables
      mattr_accessor :ignore_triggers
    end

    module TrailerWithTriggersSupport
      def trailer(stream)
        orig_show_warnings = Builder.show_warnings
        Builder.show_warnings = false # we already show them when running the migration
        triggers(stream)
        super
      ensure
        Builder.show_warnings = orig_show_warnings
      end
    end

    def triggers(stream)
      @adapter_name = @connection.adapter_name.downcase.to_sym

      all_triggers = @connection.triggers
      db_trigger_warnings = {}
      migration_trigger_builders = []

      db_triggers = whitelist_triggers(all_triggers)

      migration_triggers = HairTrigger.current_migrations(:in_rake_task => true, :previous_schema => self.class.previous_schema).map do |(_, builder)|
        definitions = []
        builder.generate.each do |statement|
          if statement =~ /\ACREATE(.*TRIGGER| FUNCTION) ([^ \n]+)/
            # poor man's unquote
            type = ($1 == ' FUNCTION' ? :function : :trigger)
            name = $2.gsub('"', '')

            definitions << [name, statement, type]
          end
        end
        {:builder => builder, :definitions => definitions}
      end

      migration_triggers.each do |migration|
        next unless migration[:definitions].all? do |(name, definition, type)|
          db_triggers[name] && (db_trigger_warnings[name] = true) && db_triggers[name] == normalize_trigger(name, definition, type)
        end

        migration[:definitions].each do |(name, _, _)|
          db_triggers.delete(name)
          db_trigger_warnings.delete(name)
        end

        migration_trigger_builders << migration[:builder]
      end

      db_triggers.to_a.sort_by{ |t| (t.first + 'a').sub(/\(/, '_') }.each do |(name, definition)|
        if db_trigger_warnings[name]
          stream.puts "  # WARNING: generating adapter-specific definition for #{name} due to a mismatch."
          stream.puts "  # either there's a bug in hairtrigger or you've messed up your migrations and/or db :-/"
        else
          stream.puts "  # no candidate create_trigger statement could be found, creating an adapter-specific one"
        end
        if definition =~ /\n/
          stream.print "  execute(<<-SQL)\n#{definition.rstrip}\n  SQL\n\n"
        else
          stream.print "  execute(#{definition.inspect})\n\n"
        end
      end

      migration_trigger_builders.each { |builder| stream.print builder.to_ruby('  ', false) + "\n\n" }
    end

    def normalize_trigger(name, definition, type)
      @adapter_name = @connection.adapter_name.downcase.to_sym

      return definition unless @adapter_name == :postgresql || @adapter_name == :postgis
      # because postgres does not preserve the original CREATE TRIGGER/
      # FUNCTION statements, its decompiled reconstruction will not match
      # ours. we work around it by creating our generated trigger/function,
      # asking postgres for its definition, and then rolling back.
      @connection.transaction(requires_new: true) do
        chars = ('a'..'z').to_a + ('0'..'9').to_a + ['_']
        test_name = '_hair_trigger_test_' + (0..43).map{ chars[(rand * chars.size).to_i] }.join
        # take of the parens for gsubbing, since this version might be quoted
        name = name[0..-3] if type == :function
        @connection.execute(definition.sub(name, test_name))
        # now add them back
        if type == :function
          test_name << '()'
          name << '()'
        end
        definition = @connection.triggers(:only => [test_name], :simple_check => true).values.first
        definition.sub!(test_name, name)
        raise ActiveRecord::Rollback
      end
      definition
    end

    def whitelist_triggers(triggers)
      triggers = triggers.reject do |name, source|
        ActiveRecord::SchemaDumper.ignore_tables.any? { |ignored_table_name| source =~ /ON\s+#{@connection.quote_table_name(ignored_table_name)}\s/ }
      end

      if Configuration.allow_tables.present?
        triggers = triggers.select do |name, source|
          Array(Configuration.allow_tables).any? { |allowed_table_name| source =~ /ON\s+#{@connection.quote_table_name(allowed_table_name)}\s/ }
        end
      end

      if Configuration.allow_triggers.present?
        triggers = triggers.select do |name, source|
          Array(Configuration.allow_triggers).any? { |allowed_trigger_name| allowed_trigger_name === name } # Triple equals to allow regexps or strings as allowed_trigger_name
        end
      end

      if Configuration.ignore_tables.present?
        triggers = triggers.reject do |name, source|
          Array(Configuration.ignore_tables).any? { |allowed_table_name| source =~ /ON\s+#{@connection.quote_table_name(allowed_table_name)}\s/ }
        end
      end

      if Configuration.ignore_triggers.present?
        triggers = triggers.reject do |name, source|
          Array(Configuration.ignore_triggers).any? { |allowed_trigger_name| allowed_trigger_name === name } # Triple equals to allow regexps or strings as allowed_trigger_name
        end
      end

      triggers
    end

    def self.included(base)
      base.class_eval do
        prepend TrailerWithTriggersSupport

        class_attribute :previous_schema
      end
    end
  end
end
