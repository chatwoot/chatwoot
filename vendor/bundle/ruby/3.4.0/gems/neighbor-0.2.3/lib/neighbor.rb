# dependencies
require "active_support"

# modules
require "neighbor/version"

module Neighbor
  class Error < StandardError; end

  module RegisterTypes
    def initialize_type_map(m = type_map)
      super
      m.register_type "cube", ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:cube)
      m.register_type "vector" do |_, _, sql_type|
        limit = extract_limit(sql_type)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:vector, limit: limit)
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require "neighbor/model"
  require "neighbor/vector"

  extend Neighbor::Model

  require "active_record/connection_adapters/postgresql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:cube] = {name: "cube"}
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

  # ensure schema can be loaded
  if ActiveRecord::VERSION::MAJOR >= 6
    ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :cube, :vector)
  else
    ActiveRecord::ConnectionAdapters::TableDefinition.define_method :cube do |*args, **options|
      args.each { |name| column(name, :cube, options) }
    end
    ActiveRecord::ConnectionAdapters::TableDefinition.define_method :vector do |*args, **options|
      args.each { |name| column(name, :vector, options) }
    end
  end

  # prevent unknown OID warning
  if ActiveRecord::VERSION::MAJOR >= 7
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(Neighbor::RegisterTypes)
  else
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Neighbor::RegisterTypes)
  end
end

require "neighbor/railtie" if defined?(Rails::Railtie)
