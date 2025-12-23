require "active_record/railtie"

module RailsApp
  class Application < Rails::Application
    config.root = File.expand_path("../../", __FILE__)
    config.i18n.enforce_available_locales = true

    if Rails.version.start_with?("7.1") && config.active_record.respond_to?(:yaml_column_permitted_classes=)
      config.active_record.yaml_column_permitted_classes = [
        String,
        Symbol,
        Integer,
        NilClass,
        Float,
        Time,
        Date,
        FalseClass,
        Hash,
        Array,
        DateTime,
        TrueClass,
        BigDecimal,
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        ActiveSupport::HashWithIndifferentAccess
      ]
    elsif !Rails.version.start_with?("5.0") && !Rails.version.start_with?("5.1") && config.active_record.respond_to?(:yaml_column_permitted_classes=)
      config.active_record.yaml_column_permitted_classes =
        %w[String Symbol Integer NilClass Float Time Date FalseClass Hash Array DateTime TrueClass BigDecimal
          ActiveSupport::TimeWithZone ActiveSupport::TimeZone ActiveSupport::HashWithIndifferentAccess]
    end

    if Rails.version >= "7.1"
      config.active_support.cache_format_version = 7.1
    end
  end
end

require "active_record/connection_adapters/sqlite3_adapter"
if ActiveRecord::ConnectionAdapters::SQLite3Adapter.respond_to?(:represent_boolean_as_integer)
  ActiveRecord::ConnectionAdapters::SQLite3Adapter.represent_boolean_as_integer = true
end
