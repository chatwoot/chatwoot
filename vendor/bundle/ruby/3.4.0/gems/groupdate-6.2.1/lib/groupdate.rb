# dependencies
require "active_support"
require "active_support/core_ext/module/attribute_accessors"
require "active_support/time"

# modules
require "groupdate/magic"
require "groupdate/series_builder"
require "groupdate/version"

# adapters
require "groupdate/adapters/base_adapter"
require "groupdate/adapters/mysql_adapter"
require "groupdate/adapters/postgresql_adapter"
require "groupdate/adapters/sqlite_adapter"

module Groupdate
  class Error < RuntimeError; end

  PERIODS = [:second, :minute, :hour, :day, :week, :month, :quarter, :year, :day_of_week, :hour_of_day, :minute_of_hour, :day_of_month, :day_of_year, :month_of_year]
  METHODS = PERIODS.map { |v| :"group_by_#{v}" } + [:group_by_period]

  mattr_accessor :week_start, :day_start, :time_zone
  self.week_start = :sunday
  self.day_start = 0

  # api for gems like ActiveMedian
  def self.process_result(relation, result, **options)
    if relation.groupdate_values
      result = Groupdate::Magic::Relation.process_result(relation, result, **options)
    end
    result
  end

  def self.adapters
    @adapters ||= {}
  end

  def self.register_adapter(name, adapter)
    Array(name).each do |n|
      adapters[n] = adapter
    end
  end
end

Groupdate.register_adapter ["Mysql2", "Mysql2Spatial", "Mysql2Rgeo"], Groupdate::Adapters::MySQLAdapter
Groupdate.register_adapter ["PostgreSQL", "PostGIS", "Redshift"], Groupdate::Adapters::PostgreSQLAdapter
Groupdate.register_adapter "SQLite", Groupdate::Adapters::SQLiteAdapter

require "groupdate/enumerable"

ActiveSupport.on_load(:active_record) do
  require "groupdate/active_record"
end
