# frozen_string_literal: true

module ActiveRecord::Import::PostgreSQLAdapter
  include ActiveRecord::Import::ImportSupport
  include ActiveRecord::Import::OnDuplicateKeyUpdateSupport

  MIN_VERSION_FOR_UPSERT = 90_500

  def insert_many( sql, values, options = {}, *args ) # :nodoc:
    number_of_inserts = 1
    returned_values = {}
    ids = []
    results = []

    base_sql, post_sql = case sql
                         when String
                           [sql, '']
                         when Array
                           [sql.shift, sql.join( ' ' )]
    end

    sql2insert = base_sql + values.join( ',' ) + post_sql

    selections = returning_selections(options)
    if selections.blank? || (options[:no_returning] && !options[:recursive])
      insert( sql2insert, *args )
    else
      returned_values = if selections.size > 1
        # Select composite columns
        db_result = select_all( sql2insert, *args )
        { values: db_result.rows, columns: db_result.columns }
      else
        { values: select_values( sql2insert, *args ) }
      end
      clear_query_cache if query_cache_enabled
    end

    if options[:returning].blank?
      ids = Array(returned_values[:values])
    elsif options[:primary_key].blank?
      options[:returning_columns] ||= returned_values[:columns]
      results = Array(returned_values[:values])
    else
      # split primary key and returning columns
      ids, results, options[:returning_columns] = split_ids_and_results(returned_values, options)
    end

    ActiveRecord::Import::Result.new([], number_of_inserts, ids, results)
  end

  def split_ids_and_results( selections, options )
    ids = []
    returning_values = []

    columns = Array(selections[:columns])
    values = Array(selections[:values])
    id_indexes = Array(options[:primary_key]).map { |key| columns.index(key) }
    returning_columns = columns.reject.with_index { |_, index| id_indexes.include?(index) }
    returning_indexes = returning_columns.map { |column| columns.index(column) }

    values.each do |value|
      value_array = Array(value)
      ids << id_indexes.map { |index| value_array[index] }
      returning_values << returning_indexes.map { |index| value_array[index] }
    end

    ids.map!(&:first) if id_indexes.size == 1
    returning_values.map!(&:first) if returning_columns.size == 1

    [ids, returning_values, returning_columns]
  end

  def next_value_for_sequence(sequence_name)
    %{nextval('#{sequence_name}')}
  end

  def post_sql_statements( table_name, options ) # :nodoc:
    sql = []

    if supports_on_duplicate_key_update?
      # Options :recursive and :on_duplicate_key_ignore are mutually exclusive
      if (options[:ignore] || options[:on_duplicate_key_ignore]) && !options[:on_duplicate_key_update] && !options[:recursive]
        sql << sql_for_on_duplicate_key_ignore( table_name, options[:on_duplicate_key_ignore] )
      end
    elsif logger && options[:on_duplicate_key_ignore] && !options[:on_duplicate_key_update]
      logger.warn "Ignoring on_duplicate_key_ignore because it is not supported by the database."
    end

    sql += super(table_name, options)

    selections = returning_selections(options)
    unless selections.blank? || (options[:no_returning] && !options[:recursive])
      sql << " RETURNING #{selections.join(', ')}"
    end

    sql
  end

  def returning_selections(options)
    selections = []
    column_names = Array(options[:model].column_names)

    selections += Array(options[:primary_key]) if options[:primary_key].present?
    selections += Array(options[:returning]) if options[:returning].present?

    selections.map do |selection|
      column_names.include?(selection.to_s) ? "\"#{selection}\"" : selection
    end
  end

  # Add a column to be updated on duplicate key update
  def add_column_for_on_duplicate_key_update( column, options = {} ) # :nodoc:
    arg = options[:on_duplicate_key_update]
    case arg
    when Hash
      columns = arg.fetch( :columns ) { arg[:columns] = [] }
      case columns
      when Array then columns << column.to_sym unless columns.include?( column.to_sym )
      when Hash then columns[column.to_sym] = column.to_sym
      end
    when Array
      arg << column.to_sym unless arg.include?( column.to_sym )
    end
  end

  # Returns a generated ON CONFLICT DO NOTHING statement given the passed
  # in +args+.
  def sql_for_on_duplicate_key_ignore( table_name, *args ) # :nodoc:
    arg = args.first
    conflict_target = sql_for_conflict_target( arg ) if arg.is_a?( Hash )
    " ON CONFLICT #{conflict_target}DO NOTHING"
  end

  # Returns a generated ON CONFLICT DO UPDATE statement given the passed
  # in +args+.
  def sql_for_on_duplicate_key_update( table_name, *args ) # :nodoc:
    arg, model, primary_key, locking_column = args
    arg = { columns: arg } if arg.is_a?( Array ) || arg.is_a?( String )
    return unless arg.is_a?( Hash )

    sql = ' ON CONFLICT '.dup
    conflict_target = sql_for_conflict_target( arg )

    columns = arg.fetch( :columns, [] )
    condition = arg[:condition]
    if columns.respond_to?( :empty? ) && columns.empty?
      return sql << "#{conflict_target}DO NOTHING"
    end

    conflict_target ||= sql_for_default_conflict_target( table_name, primary_key )
    unless conflict_target
      raise ArgumentError, 'Expected :conflict_target or :constraint_name to be specified'
    end

    sql << "#{conflict_target}DO UPDATE SET "
    case columns
    when Array
      sql << sql_for_on_duplicate_key_update_as_array( table_name, model, locking_column, columns )
    when Hash
      sql << sql_for_on_duplicate_key_update_as_hash( table_name, model, locking_column, columns )
    when String
      sql << columns
    else
      raise ArgumentError, 'Expected :columns to be an Array or Hash'
    end

    sql << " WHERE #{condition}" if condition.present?

    sql
  end

  def sql_for_on_duplicate_key_update_as_array( table_name, model, locking_column, arr ) # :nodoc:
    results = arr.map do |column|
      original_column_name = model.attribute_alias?( column ) ? model.attribute_alias( column ) : column
      qc = quote_column_name( original_column_name )
      "#{qc}=EXCLUDED.#{qc}"
    end
    increment_locking_column!(table_name, results, locking_column)
    results.join( ',' )
  end

  def sql_for_on_duplicate_key_update_as_hash( table_name, model, locking_column, hsh ) # :nodoc:
    results = hsh.map do |column1, column2|
      original_column1_name = model.attribute_alias?( column1 ) ? model.attribute_alias( column1 ) : column1
      qc1 = quote_column_name( original_column1_name )

      original_column2_name = model.attribute_alias?( column2 ) ? model.attribute_alias( column2 ) : column2
      qc2 = quote_column_name( original_column2_name )

      "#{qc1}=EXCLUDED.#{qc2}"
    end
    increment_locking_column!(table_name, results, locking_column)
    results.join( ',' )
  end

  def sql_for_conflict_target( args = {} )
    constraint_name = args[:constraint_name]
    conflict_target = args[:conflict_target]
    index_predicate = args[:index_predicate]
    if constraint_name.present?
      "ON CONSTRAINT #{constraint_name} "
    elsif conflict_target.present?
      sql = "(#{Array( conflict_target ).reject( &:blank? ).join( ', ' )}) "
      sql += "WHERE #{index_predicate} " if index_predicate
      sql
    end
  end

  def sql_for_default_conflict_target( table_name, primary_key )
    conflict_target = Array(primary_key).join(', ')
    "(#{conflict_target}) " if conflict_target.present?
  end

  # Return true if the statement is a duplicate key record error
  def duplicate_key_update_error?(exception) # :nodoc:
    exception.is_a?(ActiveRecord::StatementInvalid) && exception.to_s.include?('duplicate key')
  end

  def supports_on_duplicate_key_update?
    database_version >= MIN_VERSION_FOR_UPSERT
  end

  def supports_setting_primary_key_of_imported_objects?
    true
  end

  def database_version
    defined?(postgresql_version) ? postgresql_version : super
  end
end
