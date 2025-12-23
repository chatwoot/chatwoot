# frozen_string_literal: true

require 'optparse'

#
# == PARAMETERS
# * a - database adapter. ie: mysql, postgresql, oracle, etc.
# * n - number of objects to test with. ie: 1, 100, 1000, etc.
# * t - the table types to test. ie: myisam, innodb, memory, temporary, etc.
#
module BenchmarkOptionParser
  BANNER = "Usage: ruby #{$0} [options]\nSee ruby #{$0} -h for more options.".freeze

  def self.print_banner
    puts BANNER
  end

  def self.print_banner!
    print_banner
    exit
  end

  def self.print_options( options )
    puts "Benchmarking the following options:"
    puts "  Database adapter: #{options.adapter}"
    puts "  Number of objects: #{options.number_of_objects}"
    puts "  Table types:"
    print_valid_table_types( options, prefix: "    " )
  end

  # TODO: IMPLEMENT THIS
  def self.print_valid_table_types( options, hsh = { prefix: '' } )
    if !options.table_types.keys.empty?
      options.table_types.keys.sort.each { |type| puts hsh[:prefix].to_s + type.to_s }
    else
      puts 'No table types defined.'
    end
  end

  OptionsStruct = Struct.new( :adapter, :table_types, :delete_on_finish, :number_of_objects, :outputs,
                              :benchmark_all_types, keyword_init: true )
  OutputStruct = Struct.new( :format, :filename, keyword_init: true )
  def self.parse( args )
    options = OptionsStruct.new(
      adapter: 'mysql2',
      table_types: {},
      delete_on_finish: true,
      number_of_objects: [],
      outputs: []
    )

    opt_parser = OptionParser.new do |opts|
      opts.banner = BANNER

      # parse the database adapter
      opts.on( "a", "--adapter [String]",
        "The database adapter to use. IE: mysql, postgresql, oracle" ) do |arg|
        options.adapter = arg
      end

      # parse do_not_delete flag
      opts.on( "d", "--do-not-delete",
        "By default all records in the benchmark tables will be deleted at the end of the benchmark. " \
        "This flag indicates not to delete the benchmark data." ) do |_|
        options.delete_on_finish = false
      end

      # parse the number of row objects to test
      opts.on( "n", "--num [Integer]",
        "The number of objects to benchmark." ) do |arg|
        options.number_of_objects << arg.to_i
      end

      # parse the table types to test
      opts.on( "t", "--table-type [String]",
        "The table type to test. This can be used multiple times." ) do |arg|
        if arg =~ /^all$/
          options.table_types['all'] = options.benchmark_all_types = true
        else
          options.table_types[arg] = true
        end
      end

      # print results in CSV format
      opts.on( "--to-csv [String]", "Print results in a CSV file format" ) do |filename|
        options.outputs << OutputStruct.new( format: 'csv', filename: filename)
      end

      # print results in HTML format
      opts.on( "--to-html [String]", "Print results in HTML format" ) do |filename|
        options.outputs << OutputStruct.new( format: 'html', filename: filename )
      end
    end # end opt.parse!

    begin
      opt_parser.parse!( args )
      if options.table_types.empty?
        options.table_types['all'] = options.benchmark_all_types = true
      end
    rescue Exception
      print_banner!
    end

    options.number_of_objects = [1000] if options.number_of_objects.empty?
    options.outputs = [OutputStruct.new( format: 'html', filename: 'benchmark.html')] if options.outputs.empty?

    print_options( options )

    options
  end
end
