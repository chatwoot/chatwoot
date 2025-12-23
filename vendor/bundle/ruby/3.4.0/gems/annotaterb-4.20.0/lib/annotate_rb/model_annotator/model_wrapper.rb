# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class ModelWrapper
      # Should be the wrapper for an ActiveRecord model that serves as the source of truth of the model
      # of the model that we're annotating

      DEFAULT_TIMESTAMP_COLUMNS = %w[created_at updated_at]

      def initialize(klass, options)
        @klass = klass
        @options = options
      end

      # Gets the columns of the ActiveRecord model, processes them, and then returns them.
      def columns
        @columns ||=
          begin
            cols = raw_columns
            cols += translated_columns

            ignore_columns = @options[:ignore_columns]
            if ignore_columns
              cols = cols.reject do |col|
                col.name.match?(/#{ignore_columns}/)
              end
            end

            cols = cols.sort_by(&:name) if @options[:sort]
            cols = classified_sort(cols, @options[:grouped_polymorphic]) if @options[:classified_sort]

            cols
          end
      end

      def connection
        @klass.connection
      end

      def database_name
        connection.pool.db_config.name
      end

      # Returns the unmodified model columns
      def raw_columns
        @raw_columns ||= @klass.columns
      end

      def primary_key
        @klass.primary_key
      end

      def table_exists?
        @klass.table_exists?
      end

      def table_comments
        @klass.connection.table_comment(@klass.table_name)
      end

      def has_table_comments?
        @klass.connection.respond_to?(:table_comment) &&
          @klass.connection.table_comment(@klass.table_name).present?
      end

      def column_defaults
        @klass.column_defaults
      end

      # Add columns managed by the globalize gem if this gem is being used.
      # TODO: Audit if this is still needed, it seems like Globalize gem is no longer maintained
      def translated_columns
        return [] unless @klass.respond_to?(:translation_class)

        ignored_cols = ignored_translation_table_columns

        @klass.translation_class.columns.reject do |col|
          ignored_cols.include? col.name.to_sym
        end
      end

      def table_name
        @klass.table_name
      end

      def model_name
        @klass.name.underscore
      end

      # Calculates the max width of the schema for the model by looking at the columns, schema comments, with respect
      # to the options.
      def max_schema_info_width
        @max_schema_info_width ||=
          begin
            cols = columns

            position_of_column_comment = @options.with_default_fallback(:position_of_column_comment)
            if with_comments? && position_of_column_comment == :with_name
              column_widths = cols.map do |column|
                column.name.size + (column.comment ? Helper.width(column.comment) : 0)
              end

              max_size = column_widths.max || 0
              max_size += 2
            else
              max_size = cols.map(&:name).map(&:size).max
            end

            max_size += @options[:format_rdoc] ? 5 : 1

            max_size
          end
      end

      # TODO: Simplify this conditional
      def is_column_primary_key?(column_name)
        if primary_key
          if primary_key.is_a?(Array)
            # If the model has multiple primary keys, check if this column is one of them
            if primary_key.collect(&:to_sym).include?(column_name.to_sym)
              return true
            end
          elsif column_name.to_sym == primary_key.to_sym
            # If model has 1 primary key, check if this column is it
            return true
          end
        end

        false
      end

      def built_attributes
        @built_attributes ||= begin
          table_indices = retrieve_indexes_from_table
          columns.map do |column|
            is_primary_key = is_column_primary_key?(column.name)
            column_indices = table_indices.select { |ind| ind.columns.include?(column.name) }
            built = ColumnAnnotation::AttributesBuilder.new(column, @options, is_primary_key, column_indices, column_defaults).build
            [column.name, built]
          end.to_h
        end
      end

      def retrieve_indexes_from_table
        @indexes_from_table ||= _retrieve_indexes_from_table
      end

      def _retrieve_indexes_from_table
        table_name = @klass.table_name
        return [] unless table_name

        indexes = @klass.connection.indexes(table_name)
        return indexes if indexes.any? || !@klass.table_name_prefix

        # Try to search the table without prefix
        table_name_without_prefix = table_name.to_s.sub(@klass.table_name_prefix.to_s, "")
        begin
          @klass.connection.indexes(table_name_without_prefix)
        rescue ActiveRecord::StatementInvalid => _e
          # Mysql2 adapter behaves differently than Sqlite3 and Postgres adapter.
          # If `table_name_without_prefix` does not exist, Mysql2 will raise,
          # the other adapters will return an empty array.
          #
          # See: https://github.com/rails/rails/issues/51205
          []
        end
      end

      def with_comments?
        return @with_comments if instance_variable_defined?(:@with_comments)

        @with_comments =
          @options[:with_comment] &&
          @options[:with_column_comments] &&
          raw_columns.first.respond_to?(:comment) &&
          raw_columns.map(&:comment).any? { |comment| !comment.nil? }
      end

      def position_of_column_comment
        @position_of_column_comment ||= @options[:position_of_column_comment]
      end

      def classified_sort(cols, grouped_polymorphic)
        rest_cols = []
        timestamps = []
        associations = []
        id = nil

        # specs don't load defaults, so ensure we have defaults here
        timestamp_columns = @options[:timestamp_columns] || DEFAULT_TIMESTAMP_COLUMNS

        col_names = cols.map(&:name)

        cols.each do |c|
          if c.name.eql?("id")
            id = c
          elsif timestamp_columns.include?(c.name)
            timestamps << c
          elsif c.name[-3, 3].eql?("_id")
            associations << c
          elsif c.name[-5, 5].eql?("_type") && col_names.include?(c.name.sub(/_type$/, "_id")) && grouped_polymorphic
            # This is a polymorphic association's type column
            associations << c
          else
            rest_cols << c
          end
        end

        timestamp_order = timestamp_columns.each_with_index.to_h
        timestamps.sort_by! { |col| timestamp_order[col.name] }
        [rest_cols, associations].each { |a| a.sort_by!(&:name) }

        ([id] << rest_cols << timestamps << associations).flatten.compact
      end

      # These are the columns that the globalize gem needs to work but
      # are not necessary for the models to be displayed as annotations.
      def ignored_translation_table_columns
        [
          :id,
          :created_at,
          :updated_at,
          :locale,
          @klass.name.foreign_key.to_sym
        ]
      end

      def migration_version
        return 0 unless @options[:include_version]

        # Multi-database support: Cache migration versions per database connection to handle
        # different schema versions across primary/secondary databases correctly.
        # Example: primary → "current_version_primary", secondary → "current_version_secondary"
        connection_pool_name = connection.pool.db_config.name
        cache_key = "current_version_#{connection_pool_name}".to_sym

        if @options.get_state(cache_key).nil?
          migration_version = begin
            connection.migration_context.current_version
          rescue
            0
          end

          @options.set_state(cache_key, migration_version)
        end

        @options.get_state(cache_key)
      end
    end
  end
end
