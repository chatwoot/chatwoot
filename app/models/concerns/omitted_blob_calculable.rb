# frozen_string_literal: true

module OmittedBlobCalculable
  extend ActiveSupport::Concern

  module RelationCalculations
    def calculate(operation, column_name = nil)
      if count_operation?(operation, column_name) && default_blob_select?
        unscope(:select).calculate(operation, column_name)
      else
        super
      end
    end

    def default_blob_select?
      klass.respond_to?(:omitted_blob_columns) && select_values == klass.omitted_blob_columns
    end

    private

    def count_operation?(operation, column_name)
      operation.to_s.casecmp('count').zero? && (column_name.nil? || column_name == :all)
    end
  end

  included do
    const_get(:ActiveRecord_Relation).include(RelationCalculations)
    const_get(:ActiveRecord_AssociationRelation).include(RelationCalculations)
  end

  class_methods do
    def count(column_name = nil, &)
      return super(&) if block_given?

      if (column_name.nil? || column_name == :all) && all.default_blob_select?
        unscope(:select).count(column_name)
      else
        super
      end
    end
  end
end
