# frozen_string_literal: true

module OmittedBlobCalculable
  extend ActiveSupport::Concern

  module RelationCalculations
    def calculate(operation, column_name = nil)
      if operation.to_s.casecmp('count').zero? && (column_name.nil? || column_name == :all)
        return unscope(:select).calculate(operation, column_name)
      end

      super
    end
  end

  included do
    const_get(:ActiveRecord_Relation).include(RelationCalculations)
    const_get(:ActiveRecord_AssociationRelation).include(RelationCalculations)
  end

  class_methods do
    def count(column_name = nil)
      if column_name.nil? || column_name == :all
        unscope(:select).count(column_name)
      else
        super
      end
    end
  end
end
