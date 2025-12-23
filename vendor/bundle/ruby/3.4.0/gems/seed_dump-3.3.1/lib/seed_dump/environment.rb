class SeedDump
  module Environment

    def dump_using_environment(env = {})
      Rails.application.eager_load!

      models = retrieve_models(env) - retrieve_models_exclude(env)

      limit = retrieve_limit_value(env)
      append = retrieve_append_value(env)
      models.each do |model|
        model = model.limit(limit) if limit.present?

        SeedDump.dump(model,
                      append: append,
                      batch_size: retrieve_batch_size_value(env),
                      exclude: retrieve_exclude_value(env),
                      file: retrieve_file_value(env),
                      import: retrieve_import_value(env))

        append = true # Always append for every model after the first
                      # (append for the first model is determined by
                      # the APPEND environment variable).
      end
    end

    private
    # Internal: Array of Strings corresponding to Active Record model class names
    # that should be excluded from the dump.
    ACTIVE_RECORD_INTERNAL_MODELS = ['ActiveRecord::SchemaMigration',
                                     'ActiveRecord::InternalMetadata']

    # Internal: Retrieves an Array of Active Record model class constants to be
    # dumped.
    #
    # If a "MODEL" or "MODELS" environment variable is specified, there will be
    # an attempt to parse the environment variable String by splitting it on
    # commmas and then converting it to constant.
    #
    # Model classes that do not have corresponding database tables or database
    # records will be filtered out, as will model classes internal to Active
    # Record.
    #
    # env - Hash of environment variables from which to parse Active Record
    #       model classes. The Hash is not optional but the "MODEL" and "MODELS"
    #       keys are optional.
    #
    # Returns the Array of Active Record model classes to be dumped.
    def retrieve_models(env)
      # Parse either the "MODEL" environment variable or the "MODELS"
      # environment variable, with "MODEL" taking precedence.
      models_env = env['MODEL'] || env['MODELS']

      # If there was a use models environment variable, split it and
      # convert the given model string (e.g. "User") to an actual
      # model constant (e.g. User).
      #
      # If a models environment variable was not given, use descendants of
      # ActiveRecord::Base as the target set of models. This should be all
      # model classes in the project.
      models = if models_env
                 models_env.split(',')
                           .collect {|x| x.strip.underscore.singularize.camelize.constantize }
               else
                 ActiveRecord::Base.descendants
               end


      # Filter the set of models to exclude:
      #   - The ActiveRecord::SchemaMigration model which is internal to Rails
      #     and should not be part of the dumped data.
      #   - Models that don't have a corresponding table in the database.
      #   - Models whose corresponding database tables are empty.
      filtered_models = models.select do |model|
                          !ACTIVE_RECORD_INTERNAL_MODELS.include?(model.to_s) && \
                          model.table_exists? && \
                          model.exists?
                        end
    end

    # Internal: Returns a Boolean indicating whether the value for the "APPEND"
    # key in the given Hash is equal to the String "true" (ignoring case),
    # false if no value exists.
    def retrieve_append_value(env)
      parse_boolean_value(env['APPEND'])
    end

    # Internal: Returns a Boolean indicating whether the value for the "IMPORT"
    # key in the given Hash is equal to the String "true" (ignoring case),
    # false if  no value exists.
    def retrieve_import_value(env)
      parse_boolean_value(env['IMPORT'])
    end

    # Internal: Retrieves an Array of Class constants parsed from the value for
    # the "MODELS_EXCLUDE" key in the given Hash, and an empty Array if such
    # key exists.
    def retrieve_models_exclude(env)
      env['MODELS_EXCLUDE'].to_s
                           .split(',')
                           .collect { |x| x.strip.underscore.singularize.camelize.constantize }
    end

    # Internal: Retrieves an Integer from the value for the "LIMIT" key in the
    # given Hash, and nil if no such key exists.
    def retrieve_limit_value(env)
      retrieve_integer_value('LIMIT', env)
    end

    # Internal: Retrieves an Array of Symbols from the value for the "EXCLUDE"
    # key from the given Hash, and nil if no such key exists.
    def retrieve_exclude_value(env)
      env['EXCLUDE'] ? env['EXCLUDE'].split(',').map {|e| e.strip.to_sym} : nil
    end

    # Internal: Retrieves the value for the "FILE" key from the given Hash, and
    # 'db/seeds.rb' if no such key exists.
    def retrieve_file_value(env)
      env['FILE'] || 'db/seeds.rb'
    end

    # Internal: Retrieves an Integer from the value for the "BATCH_SIZE" key in
    # the given Hash, and nil if no such key exists.
    def retrieve_batch_size_value(env)
      retrieve_integer_value('BATCH_SIZE', env)
    end

    # Internal: Retrieves an Integer from the value for the given key in
    # the given Hash, and nil if no such key exists.
    def retrieve_integer_value(key, hash)
      hash[key] ? hash[key].to_i : nil
    end

    # Internal: Parses a Boolean from the given value.
    def parse_boolean_value(value)
      value.to_s.downcase == 'true'
    end
  end
end
