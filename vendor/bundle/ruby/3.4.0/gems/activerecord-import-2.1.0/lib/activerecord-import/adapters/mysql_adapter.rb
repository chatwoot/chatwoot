# frozen_string_literal: true

module ActiveRecord::Import::MysqlAdapter
  include ActiveRecord::Import::ImportSupport
  include ActiveRecord::Import::OnDuplicateKeyUpdateSupport

  NO_MAX_PACKET = 0
  QUERY_OVERHEAD = 8 # This was shown to be true for MySQL, but it's not clear where the overhead is from.

  # +sql+ can be a single string or an array. If it is an array all
  # elements that are in position >= 1 will be appended to the final SQL.
  def insert_many( sql, values, options = {}, *args ) # :nodoc:
    # the number of inserts default
    number_of_inserts = 0

    base_sql, post_sql = case sql
                         when String
                           [sql, '']
                         when Array
                           [sql.shift, sql.join( ' ' )]
    end

    sql_size = QUERY_OVERHEAD + base_sql.bytesize + post_sql.bytesize

    # the number of bytes the requested insert statement values will take up
    values_in_bytes = values.sum(&:bytesize)

    # the number of bytes (commas) it will take to comma separate our values
    comma_separated_bytes = values.size - 1

    # the total number of bytes required if this statement is one statement
    total_bytes = sql_size + values_in_bytes + comma_separated_bytes

    max = max_allowed_packet

    # if we can insert it all as one statement
    if max == NO_MAX_PACKET || total_bytes <= max || options[:force_single_insert]
      number_of_inserts += 1
      sql2insert = base_sql + values.join( ',' ) + post_sql
      insert( sql2insert, *args )
    else
      value_sets = ::ActiveRecord::Import::ValueSetsBytesParser.parse(values,
        reserved_bytes: sql_size,
        max_bytes: max)

      transaction(requires_new: true) do
        value_sets.each do |value_set|
          number_of_inserts += 1
          sql2insert = base_sql + value_set.join( ',' ) + post_sql
          insert( sql2insert, *args )
        end
      end
    end

    ActiveRecord::Import::Result.new([], number_of_inserts, [], [])
  end

  # Returns the maximum number of bytes that the server will allow
  # in a single packet
  def max_allowed_packet # :nodoc:
    @max_allowed_packet ||= begin
      result = execute( "SELECT @@max_allowed_packet" )
      # original Mysql gem responds to #fetch_row while Mysql2 responds to #first
      val = result.respond_to?(:fetch_row) ? result.fetch_row[0] : result.first[0]
      val.to_i
    end
  end

  def pre_sql_statements( options)
    sql = []
    sql << "IGNORE" if options[:ignore] || options[:on_duplicate_key_ignore]
    sql + super
  end

  # Add a column to be updated on duplicate key update
  def add_column_for_on_duplicate_key_update( column, options = {} ) # :nodoc:
    if (columns = options[:on_duplicate_key_update])
      case columns
      when Array then columns << column.to_sym unless columns.include?(column.to_sym)
      when Hash then columns[column.to_sym] = column.to_sym
      end
    end
  end

  # Returns a generated ON DUPLICATE KEY UPDATE statement given the passed
  # in +args+.
  def sql_for_on_duplicate_key_update( table_name, *args ) # :nodoc:
    sql = ' ON DUPLICATE KEY UPDATE '.dup
    arg, model, _primary_key, locking_column = args
    case arg
    when Array
      sql << sql_for_on_duplicate_key_update_as_array( table_name, model, locking_column, arg )
    when Hash
      sql << sql_for_on_duplicate_key_update_as_hash( table_name, model, locking_column, arg )
    when String
      sql << arg
    else
      raise ArgumentError, "Expected Array or Hash"
    end
    sql
  end

  def sql_for_on_duplicate_key_update_as_array( table_name, model, locking_column, arr ) # :nodoc:
    results = arr.map do |column|
      original_column_name = model.attribute_alias?( column ) ? model.attribute_alias( column ) : column
      qc = quote_column_name( original_column_name )
      "#{table_name}.#{qc}=VALUES(#{qc})"
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

      "#{table_name}.#{qc1}=VALUES( #{qc2} )"
    end
    increment_locking_column!(table_name, results, locking_column)
    results.join( ',')
  end

  # Return true if the statement is a duplicate key record error
  def duplicate_key_update_error?(exception) # :nodoc:
    exception.is_a?(ActiveRecord::StatementInvalid) && exception.to_s.include?('Duplicate entry')
  end

  def increment_locking_column!(table_name, results, locking_column)
    if locking_column.present?
      results << "`#{locking_column}`=#{table_name}.`#{locking_column}`+1"
    end
  end
end
