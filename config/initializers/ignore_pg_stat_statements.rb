# config/initializers/ignore_pg_stat_statements.rb
#
# Bu initializer, db/schema.rb dump edilirken
# pg_stat_statements uzantısını atlar.

module ActiveRecord
  class SchemaDumper
    private

    def extensions(stream)
      filtered = @connection.extensions - ['pg_stat_statements']
      return if filtered.empty?

      stream.puts '  # These extensions should be enabled to support this database'
      filtered.sort.each do |ext|
        stream.puts "  enable_extension #{ext.inspect}"
      end
      stream.puts
    end
  end
end
