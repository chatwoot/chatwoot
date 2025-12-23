require "active_support/concern"

module Groupdate
  module Relation
    extend ActiveSupport::Concern

    included do
      attr_accessor :groupdate_values
    end

    def calculate(*args, &block)
      # prevent calculate from being called twice
      return super if ActiveRecord::VERSION::STRING.to_f >= 6.1 && has_include?(args[1])

      default_value = [:count, :sum].include?(args[0]) ? 0 : nil
      Groupdate.process_result(self, super, default_value: default_value)
    end
  end
end
