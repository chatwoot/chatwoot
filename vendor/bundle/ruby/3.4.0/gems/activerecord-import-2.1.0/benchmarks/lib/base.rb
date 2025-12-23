# frozen_string_literal: true

class BenchmarkBase
  attr_reader :results

  # The main benchmark method dispatcher. This dispatches the benchmarks
  # to actual benchmark_xxxx methods.
  #
  # == PARAMETERS
  #  * table_types - an array of table types to benchmark
  #  * num - the number of record insertions to test
  def benchmark( table_types, num )
    array_of_cols_and_vals = build_array_of_cols_and_vals( num )
    table_types.each do |table_type|
      send( "benchmark_#{table_type}", array_of_cols_and_vals )
    end
  end

  # Returns a struct which contains two attritues, +description+ and +tms+ after performing an
  # actual benchmark.
  #
  # == PARAMETERS
  #  * description - the description of the block that is getting benchmarked
  #  * blk - the block of code to benchmark
  #
  # == RETURNS
  # A struct object with the following attributes:
  #   * description - the description of the benchmark ran
  #   * tms - a Benchmark::Tms containing the results of the benchmark

  BmStruct = Struct.new( :description, :tms, :failed, keyword_init: true )

  def bm( description, &block )
    tms = nil
    puts "Benchmarking #{description}"

    Benchmark.bm { |x| tms = x.report(&block) }
    delete_all
    failed = false

    BmStruct.new( description: description, tms: tms, failed: failed )
  end

  # Given a model class (ie: Topic), and an array of columns and value sets
  # this will perform all of the benchmarks necessary for this library.
  #
  # == PARAMETERS
  #  * model_clazz - the model class to benchmark (ie: Topic)
  #  * array_of_cols_and_vals - an array of column identifiers and value sets
  #
  # == RETURNS
  #  returns true
  def bm_model( model_clazz, array_of_cols_and_vals )
    puts
    puts "------ Benchmarking #{model_clazz.name} -------"

    cols, vals = array_of_cols_and_vals
    num_inserts = vals.size

    # add a new result group for this particular benchmark
    group = []
    @results << group

    description = "#{model_clazz.name}.create (#{num_inserts} records)"
    group << bm( description ) do
      vals.each do |values|
        model_clazz.create create_hash_for_cols_and_vals( cols, values )
      end
    end

    description = "#{model_clazz.name}.import(column, values) for #{num_inserts} records with validations"
    group << bm( description ) { model_clazz.import cols, vals, validate: true }

    description = "#{model_clazz.name}.import(columns, values) for #{num_inserts} records without validations"
    group << bm( description ) { model_clazz.import cols, vals, validate: false }

    models = []
    array_of_attrs = []

    vals.each do |arr|
      array_of_attrs << (attrs = {})
      arr.each_with_index { |value, i| attrs[cols[i]] = value }
    end
    array_of_attrs.each { |attrs| models << model_clazz.new(attrs) }

    description = "#{model_clazz.name}.import(models) for #{num_inserts} records with validations"
    group << bm( description ) { model_clazz.import models, validate: true }

    description = "#{model_clazz.name}.import(models) for #{num_inserts} records without validations"
    group << bm( description ) { model_clazz.import models, validate: false }

    true
  end

  # Returns a two element array composing of an array of columns and an array of
  # value sets given the passed +num+.
  #
  # === What is a value set?
  # A value set is an array of arrays. Each child array represents an array of value sets
  # for a given row of data.
  #
  # For example, say we wanted to represent an insertion of two records:
  #   column_names = [ 'id', 'name', 'description' ]
  #   record1 = [ 1, 'John Doe', 'A plumber' ]
  #   record2 = [ 2, 'John Smith', 'A painter' ]
  #   value_set [ record1, record2 ]
  #
  # == PARAMETER
  #  * num - the number of records to create
  def build_array_of_cols_and_vals( num )
    cols = [:my_name, :description]
    value_sets = []
    num.times { |i| value_sets << ["My Name #{i}", "My Description #{i}"] }
    [cols, value_sets]
  end

  # Returns a hash of column identifier to value mappings giving the passed in
  # value array.
  #
  # Example:
  #   cols = [ 'id', 'name', 'description' ]
  #   values = [ 1, 'John Doe', 'A plumber' ]
  #   hsh = create_hash_for_cols_and_vals( cols, values )
  #   # hsh => { 'id'=>1, 'name'=>'John Doe', 'description'=>'A plumber' }
  def create_hash_for_cols_and_vals( cols, vals )
    h = {}
    cols.zip( vals ) { |col, val| h[col] = val }
    h
  end

  # Deletes all records from all ActiveRecord subclasses
  def delete_all
    ActiveRecord::Base.send( :subclasses ).each do |subclass|
      if subclass.table_exists? && subclass.respond_to?(:delete_all)
        subclass.delete_all
      end
    end
  end

  def initialize # :nodoc:
    @results = []
  end
end
