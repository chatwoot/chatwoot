# frozen_string_literal: true

module ActiveRecord::Import::SQLite3Adapter
  include ActiveRecord::Import::ImportSupport
  include ActiveRecord::Import::OnDuplicateKeyUpdateSupport

  MIN_VERSION_FOR_IMPORT = "3.7.11"
  MIN_VERSION_FOR_UPSERT = "3.24.0"
  SQLITE_LIMIT_COMPOUND_SELECT = 500

  # Override our conformance to ActiveRecord::Import::ImportSupport interface
  # to ensure that we only support import in supported version of SQLite.
  # Which INSERT statements with multiple value sets was introduced in 3.7.11.
  def supports_import?
    database_version >= MIN_VERSION_FOR_IMPORT
  end

  def supports_on_duplicate_key_update?
    database_version >= MIN_VERSION_FOR_UPSERT
  end

  # +sql+ can be a single string or an array. If it is an array all
  # elements that are in position >= 1 will be appended to the final SQL.
  def insert_many( sql, values, _options = {}, *args ) # :nodoc:
    number_of_inserts = 0

    base_sql, post_sql = case sql
                         when String
                           [sql, '']
                         when Array
                           [sql.shift, sql.join( ' ' )]
    end

    value_sets = ::ActiveRecord::Import::ValueSetsRecordsParser.parse(values,
      max_records: SQLITE_LIMIT_COMPOUND_SELECT)

    transaction(requires_new: true) do
      value_sets.each do |value_set|
        number_of_inserts += 1
        sql2insert = base_sql + value_set.join( ',' ) + post_sql
        insert( sql2insert, *args )
      end
    end

    ActiveRecord::Import::Result.new([], number_of_inserts, [], [])
  end

  def pre_sql_statements( options )
    sql = []
    # Options :recursive and :on_duplicate_key_ignore are mutually exclusive
    if !supports_on_duplicate_key_update? && (options[:ignore] || options[:on_duplicate_key_ignore])
      sql << "OR IGNORE"
    end
    sql + super
  end

  def post_sql_statements( table_name, options ) # :nodoc:
    sql = []

    # Options :recursive and :on_duplicate_key_ignore are mutually exclusive
    if supports_on_duplicate_key_update? && ((options[:ignore] || options[:on_duplicate_key_ignore]) && !options[:on_duplicate_key_update])
      sql << sql_for_on_duplicate_key_ignore( options[:on_duplicate_key_ignore] )
    end

    sql + super
  end

  def next_value_for_sequence(sequence_name)
    %{nextval('#{sequence_name}')}
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
  def sql_for_on_duplicate_key_ignore( *args ) # :nodoc:
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

    conflict_target ||= sql_for_default_conflict_target( primary_key )
    unless conflict_target
      raise ArgumentError, 'Expected :conflict_target to be specified'
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
    conflict_target = args[:conflict_target]
    index_predicate = args[:index_predicate]
    if conflict_target.present?
      sql = "(#{Array( conflict_target ).reject( &:blank? ).join( ', ' )}) "
      sql += "WHERE #{index_predicate} " if index_predicate
      sql
    end
  end

  def sql_for_default_conflict_target( primary_key )
    conflict_target = Array(primary_key).join(', ')
    "(#{conflict_target}) " if conflict_target.present?
  end

  # Return true if the statement is a duplicate key record error
  def duplicate_key_update_error?(exception) # :nodoc:
    exception.is_a?(ActiveRecord::StatementInvalid) && exception.to_s.include?('duplicate key')
  end

  def database_version
    defined?(sqlite_version) ? sqlite_version : super
  end
end
