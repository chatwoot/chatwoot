# frozen_string_literal: true

module ActiveRecord::Import::ConnectionAdapters; end

module ActiveRecord::Import # :nodoc:
  Result = Struct.new(:failed_instances, :num_inserts, :ids, :results)

  module ImportSupport # :nodoc:
    def supports_import? # :nodoc:
      true
    end
  end

  module OnDuplicateKeyUpdateSupport # :nodoc:
    def supports_on_duplicate_key_update? # :nodoc:
      true
    end
  end

  class MissingColumnError < StandardError
    def initialize(name, index)
      super "Missing column for value <#{name}> at index #{index}"
    end
  end

  class Validator
    def initialize(klass, options = {})
      @options = options
      @validator_class = klass
      init_validations(klass)
    end

    def init_validations(klass)
      @validate_callbacks = klass._validate_callbacks.dup

      @validate_callbacks.each_with_index do |callback, i|
        filter = callback.respond_to?(:raw_filter) ? callback.raw_filter : callback.filter
        next unless filter.class.name =~ /Validations::PresenceValidator/ ||
                    (!@options[:validate_uniqueness] &&
                     filter.is_a?(ActiveRecord::Validations::UniquenessValidator))

        callback = callback.dup
        filter = filter.dup
        attrs = filter.instance_variable_get(:@attributes).dup

        if filter.is_a?(ActiveRecord::Validations::UniquenessValidator)
          attrs = []
        else
          associations = klass.reflect_on_all_associations(:belongs_to)
          associations.each do |assoc|
            if (index = attrs.index(assoc.name))
              key = assoc.foreign_key.is_a?(Array) ? assoc.foreign_key.map(&:to_sym) : assoc.foreign_key.to_sym
              attrs[index] = key unless attrs.include?(key)
            end
          end
        end

        filter.instance_variable_set(:@attributes, attrs.flatten)

        if @validate_callbacks.respond_to?(:chain, true)
          @validate_callbacks.send(:chain).tap do |chain|
            callback.instance_variable_set(:@filter, filter)
            callback.instance_variable_set(:@compiled, nil)
            chain[i] = callback
          end
        else
          callback.raw_filter = filter
          callback.filter = callback.send(:_compile_filter, filter)
          @validate_callbacks[i] = callback
        end
      end
    end

    def valid_model?(model)
      init_validations(model.class) unless model.instance_of?(@validator_class)

      validation_context = @options[:validate_with_context]
      validation_context ||= (model.new_record? ? :create : :update)
      current_context = model.send(:validation_context)

      begin
        model.send(:validation_context=, validation_context)
        model.errors.clear

        model.run_callbacks(:validation) do
          if defined?(ActiveSupport::Callbacks::Filters::Environment) # ActiveRecord >= 4.1
            runner = if @validate_callbacks.method(:compile).arity == 0
              @validate_callbacks.compile
            else # ActiveRecord >= 7.1
              @validate_callbacks.compile(nil)
            end
            env = ActiveSupport::Callbacks::Filters::Environment.new(model, false, nil)
            if runner.respond_to?(:call) # ActiveRecord < 5.1
              runner.call(env)
            else # ActiveRecord >= 5.1
              # Note that this is a gross simplification of ActiveSupport::Callbacks#run_callbacks.
              # It's technically possible for there to exist an "around" callback in the
              # :validate chain, but this would be an aberration, since Rails doesn't define
              # "around_validate". Still, rather than silently ignoring such callbacks, we
              # explicitly raise a RuntimeError, since activerecord-import was asked to perform
              # validations and it's unable to do so.
              #
              # The alternative here would be to copy-and-paste the bulk of the
              # ActiveSupport::Callbacks#run_callbacks method, which is undesirable if there's
              # no real-world use case for it.
              raise "The :validate callback chain contains an 'around' callback, which is unsupported" unless runner.final?
              runner.invoke_before(env)
              # Ensure a truthy value is returned. ActiveRecord < 7.2 always returned an array.
              runner.invoke_after(env) || []
            end
          elsif @validate_callbacks.method(:compile).arity == 0 # ActiveRecord = 4.0
            model.instance_eval @validate_callbacks.compile
          else # ActiveRecord 3.x
            model.instance_eval @validate_callbacks.compile(nil, model)
          end
        end

        model.errors.empty?
      ensure
        model.send(:validation_context=, current_context)
      end
    end
  end
end

class ActiveRecord::Associations::CollectionProxy
  def bulk_import(*args, &block)
    @association.bulk_import(*args, &block)
  end
  alias import bulk_import unless respond_to? :import
end

class ActiveRecord::Associations::CollectionAssociation
  def bulk_import(*args, &block)
    unless owner.persisted?
      raise ActiveRecord::RecordNotSaved, "You cannot call import unless the parent is saved"
    end

    options = args.last.is_a?(Hash) ? args.pop : {}

    model_klass = reflection.klass
    symbolized_foreign_key = reflection.foreign_key.to_sym

    symbolized_column_names = if model_klass.connection.respond_to?(:supports_virtual_columns?) && model_klass.connection.supports_virtual_columns?
      model_klass.columns.reject(&:virtual?).map { |c| c.name.to_sym }
    else
      model_klass.column_names.map(&:to_sym)
    end

    owner_primary_key = reflection.active_record_primary_key.to_sym
    owner_primary_key_value = owner.send(owner_primary_key)

    # assume array of model objects
    if args.last.is_a?( Array ) && args.last.first.is_a?(ActiveRecord::Base)
      if args.length == 2
        models = args.last
        column_names = args.first.dup
      else
        models = args.first
        column_names = symbolized_column_names
      end

      unless symbolized_column_names.include?(symbolized_foreign_key)
        column_names << symbolized_foreign_key
      end

      models.each do |m|
        m.public_send "#{symbolized_foreign_key}=", owner_primary_key_value
        m.public_send "#{reflection.type}=", owner.class.name if reflection.type
      end

      model_klass.bulk_import column_names, models, options

    # supports array of hash objects
    elsif args.last.is_a?( Array ) && args.last.first.is_a?(Hash)
      if args.length == 2
        array_of_hashes = args.last
        column_names = args.first.dup
        allow_extra_hash_keys = true
      else
        array_of_hashes = args.first
        column_names = array_of_hashes.first.keys
        allow_extra_hash_keys = false
      end

      symbolized_column_names = column_names.map(&:to_sym)
      unless symbolized_column_names.include?(symbolized_foreign_key)
        column_names << symbolized_foreign_key
      end

      if reflection.type && !symbolized_column_names.include?(reflection.type.to_sym)
        column_names << reflection.type.to_sym
      end

      array_of_attributes = array_of_hashes.map do |h|
        error_message = model_klass.send(:validate_hash_import, h, symbolized_column_names, allow_extra_hash_keys)

        raise ArgumentError, error_message if error_message

        column_names.map do |key|
          if key == symbolized_foreign_key
            owner_primary_key_value
          elsif reflection.type && key == reflection.type.to_sym
            owner.class.name
          else
            h[key]
          end
        end
      end

      model_klass.bulk_import column_names, array_of_attributes, options

    # supports empty array
    elsif args.last.is_a?( Array ) && args.last.empty?
      ActiveRecord::Import::Result.new([], 0, [])

    # supports 2-element array and array
    elsif args.size == 2 && args.first.is_a?( Array ) && args.last.is_a?( Array )
      column_names, array_of_attributes = args

      # dup the passed args so we don't modify unintentionally
      column_names = column_names.dup
      array_of_attributes = array_of_attributes.map(&:dup)

      symbolized_column_names = column_names.map(&:to_sym)

      if symbolized_column_names.include?(symbolized_foreign_key)
        index = symbolized_column_names.index(symbolized_foreign_key)
        array_of_attributes.each { |attrs| attrs[index] = owner_primary_key_value }
      else
        column_names << symbolized_foreign_key
        array_of_attributes.each { |attrs| attrs << owner_primary_key_value }
      end

      if reflection.type
        symbolized_type = reflection.type.to_sym
        if symbolized_column_names.include?(symbolized_type)
          index = symbolized_column_names.index(symbolized_type)
          array_of_attributes.each { |attrs| attrs[index] = owner.class.name }
        else
          column_names << symbolized_type
          array_of_attributes.each { |attrs| attrs << owner.class.name }
        end
      end

      model_klass.bulk_import column_names, array_of_attributes, options
    else
      raise ArgumentError, "Invalid arguments!"
    end
  end
  alias import bulk_import unless respond_to? :import
end

module ActiveRecord::Import::Connection
  def establish_connection(args = nil)
    conn = super(args)
    ActiveRecord::Import.load_from_connection_pool connection_pool
    conn
  end
end

class ActiveRecord::Base
  class << self
    prepend ActiveRecord::Import::Connection

    # Returns true if the current database connection adapter
    # supports import functionality, otherwise returns false.
    def supports_import?(*args)
      connection.respond_to?(:supports_import?) && connection.supports_import?(*args)
    end

    # Returns true if the current database connection adapter
    # supports on duplicate key update functionality, otherwise
    # returns false.
    def supports_on_duplicate_key_update?
      connection.respond_to?(:supports_on_duplicate_key_update?) && connection.supports_on_duplicate_key_update?
    end

    # returns true if the current database connection adapter
    # supports setting the primary key of bulk imported models, otherwise
    # returns false
    def supports_setting_primary_key_of_imported_objects?
      connection.respond_to?(:supports_setting_primary_key_of_imported_objects?) && connection.supports_setting_primary_key_of_imported_objects?
    end

    # Imports a collection of values to the database.
    #
    # This is more efficient than using ActiveRecord::Base#create or
    # ActiveRecord::Base#save multiple times. This method works well if
    # you want to create more than one record at a time and do not care
    # about having ActiveRecord objects returned for each record
    # inserted.
    #
    # This can be used with or without validations. It does not utilize
    # the ActiveRecord::Callbacks during creation/modification while
    # performing the import.
    #
    # == Usage
    #  Model.import array_of_models
    #  Model.import column_names, array_of_models
    #  Model.import array_of_hash_objects
    #  Model.import column_names, array_of_hash_objects
    #  Model.import column_names, array_of_values
    #  Model.import column_names, array_of_values, options
    #
    # ==== Model.import array_of_models
    #
    # With this form you can call _import_ passing in an array of model
    # objects that you want updated.
    #
    # ==== Model.import column_names, array_of_values
    #
    # The first parameter +column_names+ is an array of symbols or
    # strings which specify the columns that you want to update.
    #
    # The second parameter, +array_of_values+, is an array of
    # arrays. Each subarray is a single set of values for a new
    # record. The order of values in each subarray should match up to
    # the order of the +column_names+.
    #
    # ==== Model.import column_names, array_of_values, options
    #
    # The first two parameters are the same as the above form. The third
    # parameter, +options+, is a hash. This is optional. Please see
    # below for what +options+ are available.
    #
    # == Options
    # * +validate+ - true|false, tells import whether or not to use
    #   ActiveRecord validations. Validations are enforced by default.
    #   It skips the uniqueness validation for performance reasons.
    #   You can find more details here:
    #   https://github.com/zdennis/activerecord-import/issues/228
    # * +ignore+ - true|false, an alias for on_duplicate_key_ignore.
    # * +on_duplicate_key_ignore+ - true|false, tells import to discard
    #   records that contain duplicate keys. For Postgres 9.5+ it adds
    #   ON CONFLICT DO NOTHING, for MySQL it uses INSERT IGNORE, and for
    #   SQLite it uses INSERT OR IGNORE. Cannot be enabled on a
    #   recursive import. For database adapters that normally support
    #   setting primary keys on imported objects, this option prevents
    #   that from occurring.
    # * +on_duplicate_key_update+ - :all, an Array, or Hash, tells import to
    #   use MySQL's ON DUPLICATE KEY UPDATE or Postgres/SQLite ON CONFLICT
    #   DO UPDATE ability. See On Duplicate Key Update below.
    # * +synchronize+ - an array of ActiveRecord instances for the model
    #   that you are currently importing data into. This synchronizes
    #   existing model instances in memory with updates from the import.
    # * +timestamps+ - true|false, tells import to not add timestamps
    #   (if false) even if record timestamps is disabled in ActiveRecord::Base
    # * +recursive+ - true|false, tells import to import all has_many/has_one
    #   associations if the adapter supports setting the primary keys of the
    #   newly imported objects. PostgreSQL only.
    # * +batch_size+ - an integer value to specify the max number of records to
    #   include per insert. Defaults to the total number of records to import.
    #
    # == Examples
    #  class BlogPost < ActiveRecord::Base ; end
    #
    #  # Example using array of model objects
    #  posts = [ BlogPost.new author_name: 'Zach Dennis', title: 'AREXT',
    #            BlogPost.new author_name: 'Zach Dennis', title: 'AREXT2',
    #            BlogPost.new author_name: 'Zach Dennis', title: 'AREXT3' ]
    #  BlogPost.import posts
    #
    #  # Example using array_of_hash_objects
    #  # NOTE: column_names will be determined by using the keys of the first hash in the array. If later hashes in the
    #  # array have different keys an exception will be raised. If you have hashes to import with different sets of keys
    #  # we recommend grouping these into batches before importing.
    #  values = [ {author_name: 'zdennis', title: 'test post'} ], [ {author_name: 'jdoe', title: 'another test post'} ] ]
    #  BlogPost.import values
    #
    #  # Example using column_names and array_of_hash_objects
    #  columns = [ :author_name, :title ]
    #  values = [ {author_name: 'zdennis', title: 'test post'} ], [ {author_name: 'jdoe', title: 'another test post'} ] ]
    #  BlogPost.import columns, values
    #
    #  # Example using column_names and array_of_values
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
    #  BlogPost.import columns, values
    #
    #  # Example using column_names, array_of_value and options
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'zdennis', 'test post' ], [ 'jdoe', 'another test post' ] ]
    #  BlogPost.import( columns, values, validate: false  )
    #
    #  # Example synchronizing existing instances in memory
    #  post = BlogPost.where(author_name: 'zdennis').first
    #  puts post.author_name # => 'zdennis'
    #  columns = [ :author_name, :title ]
    #  values = [ [ 'yoda', 'test post' ] ]
    #  BlogPost.import posts, synchronize: [ post ]
    #  puts post.author_name # => 'yoda'
    #
    #  # Example synchronizing unsaved/new instances in memory by using a uniqued imported field
    #  posts = [BlogPost.new(title: "Foo"), BlogPost.new(title: "Bar")]
    #  BlogPost.import posts, synchronize: posts, synchronize_keys: [:title]
    #  puts posts.first.persisted? # => true
    #
    # == On Duplicate Key Update (MySQL)
    #
    # The :on_duplicate_key_update option can be either :all, an Array, or a Hash.
    #
    # ==== Using :all
    #
    # The :on_duplicate_key_update option can be set to :all. All columns
    # other than the primary key are updated. If a list of column names is
    # supplied, only those columns will be updated. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: :all
    #
    # ==== Using an Array
    #
    # The :on_duplicate_key_update option can be an array of column
    # names. The column names are the only fields that are updated if
    # a duplicate record is found. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: [ :date_modified, :content, :author ]
    #
    # ====  Using A Hash
    #
    # The :on_duplicate_key_update option can be a hash of column names
    # to model attribute name mappings. This gives you finer grained
    # control over what fields are updated with what attributes on your
    # model. Below is an example:
    #
    #   BlogPost.import columns, attributes, on_duplicate_key_update: { title: :title }
    #
    # == On Duplicate Key Update (Postgres 9.5+ and SQLite 3.24+)
    #
    # The :on_duplicate_key_update option can be :all, an Array, or a Hash with up to
    # three attributes, :conflict_target (and optionally :index_predicate) or
    # :constraint_name (Postgres), and :columns.
    #
    # ==== Using :all
    #
    # The :on_duplicate_key_update option can be set to :all. All columns
    # other than the primary key are updated. If a list of column names is
    # supplied, only those columns will be updated. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: :all
    #
    # ==== Using an Array
    #
    # The :on_duplicate_key_update option can be an array of column
    # names. This option only handles inserts that conflict with the
    # primary key. If a table does not have a primary key, this will
    # not work. The column names are the only fields that are updated
    # if a duplicate record is found. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: [ :date_modified, :content, :author ]
    #
    # ====  Using a Hash
    #
    # The :on_duplicate_key_update option can be a hash with up to three
    # attributes, :conflict_target (and optionally :index_predicate) or
    # :constraint_name, and :columns. Unlike MySQL, Postgres requires the
    # conflicting constraint to be explicitly specified. Using this option
    # allows you to specify a constraint other than the primary key.
    #
    # ===== :conflict_target
    #
    # The :conflict_target attribute specifies the columns that make up the
    # conflicting unique constraint and can be a single column or an array of
    # column names. This attribute is ignored if :constraint_name is included,
    # but it is the preferred method of identifying a constraint. It will
    # default to the primary key. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { conflict_target: [ :author_id, :slug ], columns: [ :date_modified ] }
    #
    # ===== :index_predicate
    #
    # The :index_predicate attribute optionally specifies a WHERE condition
    # on :conflict_target, which is required for matching against partial
    # indexes. This attribute is ignored if :constraint_name is included.
    # Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { conflict_target: [ :author_id, :slug ], index_predicate: 'status <> 0', columns: [ :date_modified ] }
    #
    # ===== :constraint_name
    #
    # The :constraint_name attribute explicitly identifies the conflicting
    # unique index by name. Postgres documentation discourages using this method
    # of identifying an index unless absolutely necessary. Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { constraint_name: :blog_posts_pkey, columns: [ :date_modified ] }
    #
    # ===== :condition
    #
    # The :condition attribute optionally specifies a WHERE condition
    # on :conflict_action. Only rows for which this expression returns true will be updated.
    # Note that it's evaluated last, after a conflict has been identified as a candidate to update.
    # Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { conflict_target: [ :author_id ], condition: "blog_posts.title NOT LIKE '%sample%'", columns: [ :author_name ] }
    #
    # ===== :columns
    #
    # The :columns attribute can be either :all, an Array, or a Hash.
    #
    # ===== Using :all
    #
    # The :columns attribute can be :all. All columns other than the primary key will be updated.
    # If a list of column names is supplied, only those columns will be updated.
    # Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { conflict_target: :slug, columns: :all }
    #
    # ===== Using an Array
    #
    # The :columns attribute can be an array of column names. The column names
    # are the only fields that are updated if a duplicate record is found.
    # Below is an example:
    #
    #   BlogPost.import columns, values, on_duplicate_key_update: { conflict_target: :slug, columns: [ :date_modified, :content, :author ] }
    #
    # =====  Using a Hash
    #
    # The :columns option can be a hash of column names to model attribute name
    # mappings. This gives you finer grained control over what fields are updated
    # with what attributes on your model. Below is an example:
    #
    #   BlogPost.import columns, attributes, on_duplicate_key_update: { conflict_target: :slug, columns: { title: :title } }
    #
    # = Returns
    # This returns an object which responds to +failed_instances+ and +num_inserts+.
    # * failed_instances - an array of objects that fails validation and were not committed to the database. An empty array if no validation is performed.
    # * num_inserts - the number of insert statements it took to import the data
    # * ids - the primary keys of the imported ids if the adapter supports it, otherwise an empty array.
    # * results - import results if the adapter supports it, otherwise an empty array.
    def bulk_import(*args)
      if args.first.is_a?( Array ) && args.first.first.is_a?(ActiveRecord::Base)
        options = {}
        options.merge!( args.pop ) if args.last.is_a?(Hash)

        models = args.first
        import_helper(models, options)
      else
        import_helper(*args)
      end
    end
    alias import bulk_import unless ActiveRecord::Base.respond_to? :import

    # Imports a collection of values if all values are valid. Import fails at the
    # first encountered validation error and raises ActiveRecord::RecordInvalid
    # with the failed instance.
    def bulk_import!(*args)
      options = args.last.is_a?( Hash ) ? args.pop : {}
      options[:validate] = true
      options[:raise_error] = true

      bulk_import(*args, options)
    end
    alias import! bulk_import! unless ActiveRecord::Base.respond_to? :import!

    def import_helper( *args )
      options = { model: self, validate: true, timestamps: true, track_validation_failures: false }
      options.merge!( args.pop ) if args.last.is_a? Hash
      # making sure that current model's primary key is used
      options[:primary_key] = primary_key
      options[:locking_column] = locking_column if locking_enabled?

      is_validating = options[:validate_with_context].present? ? true : options[:validate]
      validator = ActiveRecord::Import::Validator.new(self, options)

      # assume array of model objects
      if args.last.is_a?( Array ) && args.last.first.is_a?(ActiveRecord::Base)
        if args.length == 2
          models = args.last
          column_names = args.first.dup
        else
          models = args.first
          column_names = if connection.respond_to?(:supports_virtual_columns?) && connection.supports_virtual_columns?
            columns.reject(&:virtual?).map(&:name)
          else
            self.column_names.dup
          end
        end

        if models.first.id.nil?
          Array(primary_key).each do |c|
            if column_names.include?(c) && schema_columns_hash[c].type == :uuid
              column_names.delete(c)
            end
          end
        end

        update_attrs = if record_timestamps && options[:timestamps]
          if respond_to?(:timestamp_attributes_for_update, true)
            send(:timestamp_attributes_for_update).map(&:to_sym)
          else
            allocate.send(:timestamp_attributes_for_update_in_model)
          end
        end

        array_of_attributes = []

        models.each do |model|
          if supports_setting_primary_key_of_imported_objects?
            load_association_ids(model)
          end

          if is_validating && !validator.valid_model?(model)
            raise(ActiveRecord::RecordInvalid, model) if options[:raise_error]
            next
          end

          array_of_attributes << column_names.map do |name|
            if model.persisted? &&
               update_attrs && update_attrs.include?(name.to_sym) &&
               !model.send("#{name}_changed?")
              nil
            else
              model.read_attribute(name.to_s)
            end
          end
        end
        # supports array of hash objects
      elsif args.last.is_a?( Array ) && args.last.first.is_a?(Hash)
        if args.length == 2
          array_of_hashes = args.last
          column_names = args.first.dup
          allow_extra_hash_keys = true
        else
          array_of_hashes = args.first
          column_names = array_of_hashes.first.keys
          allow_extra_hash_keys = false
        end

        array_of_attributes = array_of_hashes.map do |h|
          error_message = validate_hash_import(h, column_names, allow_extra_hash_keys)

          raise ArgumentError, error_message if error_message

          column_names.map do |key|
            h[key]
          end
        end
        # supports empty array
      elsif args.last.is_a?( Array ) && args.last.empty?
        return ActiveRecord::Import::Result.new([], 0, [], [])
        # supports 2-element array and array
      elsif args.size == 2 && args.first.is_a?( Array ) && args.last.is_a?( Array )

        unless args.last.first.is_a?(Array)
          raise ArgumentError, "Last argument should be a two dimensional array '[[]]'. First element in array was a #{args.last.first.class}"
        end

        column_names, array_of_attributes = args

        # dup the passed args so we don't modify unintentionally
        column_names = column_names.dup
        array_of_attributes = array_of_attributes.map(&:dup)
      else
        raise ArgumentError, "Invalid arguments!"
      end

      # Force the primary key col into the insert if it's not
      # on the list and we are using a sequence and stuff a nil
      # value for it into each row so the sequencer will fire later
      symbolized_column_names = Array(column_names).map(&:to_sym)
      symbolized_primary_key = Array(primary_key).map(&:to_sym)

      if !symbolized_primary_key.to_set.subset?(symbolized_column_names.to_set) && connection.prefetch_primary_key? && sequence_name
        column_count = column_names.size
        column_names.concat(Array(primary_key)).uniq!
        columns_added = column_names.size - column_count
        new_fields = Array.new(columns_added)
        array_of_attributes.each { |a| a.concat(new_fields) }
      end

      # Don't modify incoming arguments
      on_duplicate_key_update = options[:on_duplicate_key_update]
      if on_duplicate_key_update
        updatable_columns = symbolized_column_names.reject { |c| symbolized_primary_key.include? c }
        options[:on_duplicate_key_update] = if on_duplicate_key_update.is_a?(Hash)
          on_duplicate_key_update.each_with_object({}) do |(k, v), duped_options|
            duped_options[k] = if k == :columns && v == :all
              updatable_columns
            elsif v.duplicable?
              v.dup
            else
              v
            end
          end
        elsif on_duplicate_key_update == :all
          updatable_columns
        elsif on_duplicate_key_update.duplicable?
          on_duplicate_key_update.dup
        else
          on_duplicate_key_update
        end
      end

      timestamps = {}

      # record timestamps unless disabled in ActiveRecord::Base
      if record_timestamps && options[:timestamps]
        timestamps = add_special_rails_stamps column_names, array_of_attributes, options
      end

      return_obj = if is_validating
        import_with_validations( column_names, array_of_attributes, options ) do |failed_instances|
          if models
            models.each_with_index do |m, i|
              next unless m.errors.any?

              failed_instances << (options[:track_validation_failures] ? [i, m] : m)
            end
          else
            # create instances for each of our column/value sets
            arr = validations_array_for_column_names_and_attributes( column_names, array_of_attributes )

            # keep track of the instance and the position it is currently at. if this fails
            # validation we'll use the index to remove it from the array_of_attributes
            arr.each_with_index do |hsh, i|
              # utilize block initializer syntax to prevent failure when 'mass_assignment_sanitizer = :strict'
              model = new do |m|
                hsh.each_pair { |k, v| m[k] = v }
              end

              next if validator.valid_model?(model)
              raise(ActiveRecord::RecordInvalid, model) if options[:raise_error]

              array_of_attributes[i] = nil
              failure = model.dup
              failure.errors.send(:initialize_dup, model.errors)
              failed_instances << (options[:track_validation_failures] ? [i, failure] : failure )
            end
            array_of_attributes.compact!
          end
        end
      else
        import_without_validations_or_callbacks( column_names, array_of_attributes, options )
      end

      if options[:synchronize]
        sync_keys = options[:synchronize_keys] || Array(primary_key)
        synchronize( options[:synchronize], sync_keys)
      end
      return_obj.num_inserts = 0 if return_obj.num_inserts.nil?

      # if we have ids, then set the id on the models and mark the models as clean.
      if models && supports_setting_primary_key_of_imported_objects?
        set_attributes_and_mark_clean(models, return_obj, timestamps, options)

        # if there are auto-save associations on the models we imported that are new, import them as well
        if options[:recursive]
          options[:on_duplicate_key_update] = on_duplicate_key_update unless on_duplicate_key_update.nil?
          import_associations(models, options.dup.merge(validate: false))
        end
      end

      return_obj
    end

    # Imports the passed in +column_names+ and +array_of_attributes+
    # given the passed in +options+ Hash with validations. Returns an
    # object with the methods +failed_instances+ and +num_inserts+.
    # +failed_instances+ is an array of instances that failed validations.
    # +num_inserts+ is the number of inserts it took to import the data. See
    # ActiveRecord::Base.import for more information on
    # +column_names+, +array_of_attributes+ and +options+.
    def import_with_validations( column_names, array_of_attributes, options = {} )
      failed_instances = []

      yield failed_instances if block_given?

      result = if options[:all_or_none] && failed_instances.any?
        ActiveRecord::Import::Result.new([], 0, [], [])
      else
        import_without_validations_or_callbacks( column_names, array_of_attributes, options )
      end
      ActiveRecord::Import::Result.new(failed_instances, result.num_inserts, result.ids, result.results)
    end

    # Imports the passed in +column_names+ and +array_of_attributes+
    # given the passed in +options+ Hash. This will return the number
    # of insert operations it took to create these records without
    # validations or callbacks. See ActiveRecord::Base.import for more
    # information on +column_names+, +array_of_attributes_ and
    # +options+.
    def import_without_validations_or_callbacks( column_names, array_of_attributes, options = {} )
      return ActiveRecord::Import::Result.new([], 0, [], []) if array_of_attributes.empty?

      column_names = column_names.map do |name|
        original_name = attribute_alias?(name) ? attribute_alias(name) : name
        original_name.to_sym
      end
      scope_columns, scope_values = scope_attributes.to_a.transpose

      unless scope_columns.blank?
        scope_columns.zip(scope_values).each do |name, value|
          name_as_sym = name.to_sym
          next if column_names.include?(name_as_sym) || name_as_sym == inheritance_column.to_sym
          column_names << name_as_sym
          array_of_attributes.each { |attrs| attrs << value }
        end
      end

      if finder_needs_type_condition? && !column_names.include?(inheritance_column.to_sym)
        column_names << inheritance_column.to_sym
        array_of_attributes.each { |attrs| attrs << sti_name }
      end

      columns = column_names.each_with_index.map do |name, i|
        column = schema_columns_hash[name.to_s]
        raise ActiveRecord::Import::MissingColumnError.new(name.to_s, i) if column.nil?
        column
      end

      columns_sql = "(#{column_names.map { |name| connection.quote_column_name(name) }.join(',')})"
      pre_sql_statements = connection.pre_sql_statements( options )
      insert_sql = ['INSERT', pre_sql_statements, "INTO #{quoted_table_name} #{columns_sql} VALUES "]
      insert_sql = insert_sql.flatten.join(' ')
      values_sql = values_sql_for_columns_and_attributes(columns, array_of_attributes)

      number_inserted = 0
      ids = []
      results = []
      if supports_import?
        # generate the sql
        post_sql_statements = connection.post_sql_statements( quoted_table_name, options )
        import_size = values_sql.size

        batch_size = options[:batch_size] || import_size
        run_proc = options[:batch_size].to_i.positive? && options[:batch_progress].respond_to?( :call )
        progress_proc = options[:batch_progress]
        current_batch = 0
        batches = (import_size / batch_size.to_f).ceil

        values_sql.each_slice(batch_size) do |batch_values|
          batch_started_at = Time.now.to_i

          # perform the inserts
          result = connection.insert_many( [insert_sql, post_sql_statements].flatten,
            batch_values,
            options,
            "#{model_name} Create Many" )

          number_inserted += result.num_inserts
          ids += result.ids
          results += result.results
          current_batch += 1

          progress_proc.call(import_size, batches, current_batch, Time.now.to_i - batch_started_at) if run_proc
        end
      else
        transaction(requires_new: true) do
          values_sql.each do |values|
            ids << connection.insert(insert_sql + values)
            number_inserted += 1
          end
        end
      end
      ActiveRecord::Import::Result.new([], number_inserted, ids, results)
    end

    private

    def associated_options(options, association)
      return options unless options.key?(:recursive_on_duplicate_key_update)

      options.merge(
        on_duplicate_key_update: options[:recursive_on_duplicate_key_update][association]
      )
    end

    def set_attributes_and_mark_clean(models, import_result, timestamps, options)
      return if models.nil?
      models -= import_result.failed_instances

      # if ids were returned for all models we know all were updated
      if models.size == import_result.ids.size
        import_result.ids.each_with_index do |id, index|
          model = models[index]
          model.id = id

          timestamps.each do |attr, value|
            model.send("#{attr}=", value) if model.send(attr).nil?
          end
        end
      end

      deserialize_value = lambda do |column, value|
        column = schema_columns_hash[column]
        return value unless column
        if respond_to?(:type_caster)
          type = type_for_attribute(column.name)
          type.deserialize(value)
        elsif column.respond_to?(:type_cast_from_database)
          column.type_cast_from_database(value)
        else
          value
        end
      end

      set_value = lambda do |model, column, value|
        val = deserialize_value.call(column, value)
        if model.attribute_names.include?(column)
          model.send("#{column}=", val)
        else
          attributes = attributes_builder.build_from_database(model.attributes.merge(column => val))
          model.instance_variable_set(:@attributes, attributes)
        end
      end

      columns = Array(options[:returning_columns])
      results = Array(import_result.results)
      if models.size == results.size
        single_column = columns.first if columns.size == 1
        results.each_with_index do |result, index|
          model = models[index]

          if single_column
            set_value.call(model, single_column, result)
          else
            columns.each_with_index do |column, col_index|
              set_value.call(model, column, result[col_index])
            end
          end
        end
      end

      models.each do |model|
        if model.respond_to?(:changes_applied) # Rails 4.1.8 and higher
          model.changes_internally_applied if model.respond_to?(:changes_internally_applied) # legacy behavior for Rails 5.1
          model.changes_applied
        elsif model.respond_to?(:clear_changes_information) # Rails 4.0 and higher
          model.clear_changes_information
        else # Rails 3.2
          model.instance_variable_get(:@changed_attributes).clear
        end
        model.instance_variable_set(:@new_record, false)
      end
    end

    # Sync belongs_to association ids with foreign key field
    def load_association_ids(model)
      changed_columns = model.changed
      association_reflections = model.class.reflect_on_all_associations(:belongs_to)
      association_reflections.each do |association_reflection|
        next if association_reflection.options[:polymorphic]

        column_names = Array(association_reflection.foreign_key).map(&:to_s)
        column_names.each_with_index do |column_name, column_index|
          next if changed_columns.include?(column_name)

          association = model.association(association_reflection.name)
          association = association.target
          next if association.blank? || model.public_send(column_name).present?

          association_primary_key = Array(association_reflection.association_primary_key.tr("[]:", "").split(", "))[column_index]
          model.public_send("#{column_name}=", association.send(association_primary_key))
        end
      end
    end

    def import_associations(models, options)
      # now, for all the dirty associations, collect them into a new set of models, then recurse.
      # notes:
      #    does not handle associations that reference themselves
      #    should probably take a hash to associations to follow.
      return if models.nil?
      associated_objects_by_class = {}
      models.each { |model| find_associated_objects_for_import(associated_objects_by_class, model) }

      # :on_duplicate_key_update only supported for all fields
      options.delete(:on_duplicate_key_update) unless options[:on_duplicate_key_update] == :all
      # :returning not supported for associations
      options.delete(:returning)

      associated_objects_by_class.each_value do |associations|
        associations.each do |association, associated_records|
          next if associated_records.empty?

          associated_class = associated_records.first.class
          associated_class.bulk_import(associated_records,
                                       associated_options(options, association))
        end
      end
    end

    def schema_columns_hash
      if respond_to?(:ignored_columns) && ignored_columns.any?
        connection.schema_cache.columns_hash(table_name)
      else
        columns_hash
      end
    end

    # We are eventually going to call Class.import <objects> so we build up a hash
    # of class => objects to import.
    def find_associated_objects_for_import(associated_objects_by_class, model)
      associated_objects_by_class[model.class.name] ||= {}
      return associated_objects_by_class unless model.id

      association_reflections =
        model.class.reflect_on_all_associations(:has_one) +
        model.class.reflect_on_all_associations(:has_many)
      association_reflections.each do |association_reflection|
        associated_objects_by_class[model.class.name][association_reflection.name] ||= []

        association = model.association(association_reflection.name)
        association.loaded!

        # Wrap target in an array if not already
        association = Array(association.target)

        changed_objects = association.select { |a| a.new_record? || a.changed? }
        changed_objects.each do |child|
          Array(association_reflection.inverse_of&.foreign_key || association_reflection.foreign_key).each_with_index do |column, index|
            child.public_send("#{column}=", Array(model.id)[index])
          end

          # For polymorphic associations
          association_name = if model.class.respond_to?(:polymorphic_name)
            model.class.polymorphic_name
          else
            model.class.base_class
          end
          association_reflection.type.try do |type|
            child.public_send("#{type}=", association_name)
          end
        end
        associated_objects_by_class[model.class.name][association_reflection.name].concat changed_objects
      end
      associated_objects_by_class
    end

    # Returns SQL the VALUES for an INSERT statement given the passed in +columns+
    # and +array_of_attributes+.
    def values_sql_for_columns_and_attributes(columns, array_of_attributes) # :nodoc:
      # connection gets called a *lot* in this high intensity loop.
      # Reuse the same one w/in the loop, otherwise it would keep being re-retreived (= lots of time for large imports)
      connection_memo = connection

      array_of_attributes.map do |arr|
        my_values = arr.each_with_index.map do |val, j|
          column = columns[j]

          # be sure to query sequence_name *last*, only if cheaper tests fail, because it's costly
          if val.nil? && Array(primary_key).first == column.name && !sequence_name.blank?
            connection_memo.next_value_for_sequence(sequence_name)
          elsif val.respond_to?(:to_sql)
            "(#{val.to_sql})"
          elsif column
            if respond_to?(:type_caster)                                         # Rails 5.0 and higher
              type = type_for_attribute(column.name)
              val = !type.respond_to?(:subtype) && type.type == :boolean ? type.cast(val) : type.serialize(val)
              connection_memo.quote(val)
            elsif column.respond_to?(:type_cast_from_user)                       # Rails 4.2
              connection_memo.quote(column.type_cast_from_user(val), column)
            else                                                                 # Rails 3.2, 4.0 and 4.1
              if serialized_attributes.include?(column.name)
                val = serialized_attributes[column.name].dump(val)
              end
              # Fixes #443 to support binary (i.e. bytea) columns on PG
              val = column.type_cast(val) unless column.type && column.type.to_sym == :binary
              connection_memo.quote(val, column)
            end
          else
            raise ArgumentError, "Number of values (#{arr.length}) exceeds number of columns (#{columns.length})"
          end
        end
        "(#{my_values.join(',')})"
      end
    end

    def add_special_rails_stamps( column_names, array_of_attributes, options )
      timestamp_columns = {}
      timestamps        = {}

      if respond_to?(:all_timestamp_attributes_in_model, true) # Rails 5.1 and higher
        timestamp_columns[:create] = timestamp_attributes_for_create_in_model
        timestamp_columns[:update] = timestamp_attributes_for_update_in_model
      else
        instance = allocate
        timestamp_columns[:create] = instance.send(:timestamp_attributes_for_create_in_model)
        timestamp_columns[:update] = instance.send(:timestamp_attributes_for_update_in_model)
      end

      # use tz as set in ActiveRecord::Base
      default_timezone = if ActiveRecord.respond_to?(:default_timezone)
        ActiveRecord.default_timezone
      else
        ActiveRecord::Base.default_timezone
      end
      timestamp = default_timezone == :utc ? Time.now.utc : Time.now

      [:create, :update].each do |action|
        timestamp_columns[action].each do |column|
          column = column.to_s
          timestamps[column] = timestamp

          index = column_names.index(column) || column_names.index(column.to_sym)
          if index
            # replace every instance of the array of attributes with our value
            array_of_attributes.each { |arr| arr[index] = timestamp if arr[index].nil? }
          else
            column_names << column
            array_of_attributes.each { |arr| arr << timestamp }
          end

          if supports_on_duplicate_key_update? && action == :update
            connection.add_column_for_on_duplicate_key_update(column, options)
          end
        end
      end

      timestamps
    end

    # Returns an Array of Hashes for the passed in +column_names+ and +array_of_attributes+.
    def validations_array_for_column_names_and_attributes( column_names, array_of_attributes ) # :nodoc:
      array_of_attributes.map { |values| Hash[column_names.zip(values)] }
    end

    # Checks that the imported hash has the required_keys, optionally also checks that the hash has
    # no keys beyond those required when `allow_extra_keys` is false.
    # returns `nil` if validation passes, or an error message if it fails
    def validate_hash_import(hash, required_keys, allow_extra_keys) # :nodoc:
      extra_keys = allow_extra_keys ? [] : hash.keys - required_keys
      missing_keys = required_keys - hash.keys

      return nil if extra_keys.empty? && missing_keys.empty?

      if allow_extra_keys
        <<-EOS
Hash key mismatch.

When importing an array of hashes with provided columns_names, each hash must contain keys for all column_names.

Required keys: #{required_keys}
Missing keys: #{missing_keys}

Hash: #{hash}
        EOS
      else
        <<-EOS
Hash key mismatch.

When importing an array of hashes, all hashes must have the same keys.
If you have records that are missing some values, we recommend you either set default values
for the missing keys or group these records into batches by key set before importing.

Required keys: #{required_keys}
Extra keys: #{extra_keys}
Missing keys: #{missing_keys}

Hash: #{hash}
        EOS
      end
    end
  end
end
