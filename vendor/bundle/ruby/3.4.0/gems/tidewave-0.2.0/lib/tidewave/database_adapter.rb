# frozen_string_literal: true

module Tidewave
  class DatabaseAdapter
    class << self
      def current
        @current ||= create_adapter
      end

      def create_adapter
        orm_type = Rails.application.config.tidewave.preferred_orm
        case orm_type
        when :active_record
          require_relative "database_adapters/active_record"
          DatabaseAdapters::ActiveRecord.new
        when :sequel
          require_relative "database_adapters/sequel"
          DatabaseAdapters::Sequel.new
        else
          raise "Unknown preferred ORM: #{orm_type}"
        end
      end
    end

    def execute_query(query, arguments = [])
      raise NotImplementedError, "Subclasses must implement execute_query"
    end

    def get_base_class
      raise NotImplementedError, "Subclasses must implement get_base_class"
    end
  end
end
