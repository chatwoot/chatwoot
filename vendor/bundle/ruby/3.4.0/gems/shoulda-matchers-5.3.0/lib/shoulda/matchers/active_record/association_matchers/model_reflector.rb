module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class ModelReflector
          delegate(
            :associated_class,
            :association_foreign_key,
            :foreign_key,
            :has_and_belongs_to_many_name,
            :join_table_name,
            :polymorphic?,
            :validate_inverse_of_through_association!,
            to: :reflection,
          )

          delegate(
            :through?,
            to: :reflection,
            allow_nil: true,
          )

          def initialize(subject, name)
            @subject = subject
            @name = name
          end

          def association_relation
            reflection.association_relation(subject)
          end

          def reflection
            @_reflection ||= reflect_on_association(name)
          end

          def reflect_on_association(name)
            reflection = model_class.reflect_on_association(name)

            if reflection
              ModelReflection.new(reflection)
            end
          end

          def model_class
            subject.class
          end

          def build_relation_with_clause(name, value)
            case name
            when :conditions
              associated_class.where(value)
            when :order
              associated_class.order(value)
            else
              raise ArgumentError, "Unknown clause '#{name}'"
            end
          end

          def extract_relation_clause_from(relation, name)
            case name
            when :conditions
              relation.where_values_hash
            when :order
              relation.order_values.map do |value|
                value_as_sql(value)
              end.join(', ')
            else
              raise ArgumentError, "Unknown clause '#{name}'"
            end
          end

          protected

          attr_reader :subject, :name

          def value_as_sql(value)
            if value.respond_to?(:to_sql)
              value.to_sql
            else
              value
            end
          end
        end
      end
    end
  end
end
