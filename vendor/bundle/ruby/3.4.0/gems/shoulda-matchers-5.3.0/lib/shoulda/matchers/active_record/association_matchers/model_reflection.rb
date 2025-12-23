require 'delegate'

module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class ModelReflection < SimpleDelegator
          def initialize(reflection)
            super(reflection)
            @reflection = reflection
            @subject = reflection.active_record
          end

          def associated_class
            reflection.klass
          end

          def polymorphic?
            reflection.options[:polymorphic]
          end

          def through?
            reflection.options[:through]
          end

          def join_table_name
            join_table_name =
              has_and_belongs_to_many_name_table_name || reflection.join_table
            join_table_name.to_s
          end

          def association_relation(related_instance)
            relation = associated_class.all

            if reflection.scope
              # Source: AR::Associations::AssociationScope#eval_scope
              relation.instance_exec(related_instance, &reflection.scope)
            else
              relation
            end
          end

          def foreign_key
            if has_and_belongs_to_many_reflection
              has_and_belongs_to_many_reflection.foreign_key
            elsif reflection.respond_to?(:foreign_key)
              reflection.foreign_key
            else
              reflection.primary_key_name
            end
          end

          def association_foreign_key
            if has_and_belongs_to_many_reflection
              join_model = has_and_belongs_to_many_reflection.options[:class]
              join_model.right_reflection.foreign_key
            else
              reflection.association_foreign_key
            end
          end

          def validate_inverse_of_through_association!
            if through?
              reflection.check_validity!
            end
          end

          def has_and_belongs_to_many_name
            reflection.options[:through]
          end

          protected

          attr_reader :reflection, :subject

          private

          def has_and_belongs_to_many_name_table_name
            has_and_belongs_to_many_reflection&.table_name
          end

          def has_and_belongs_to_many_reflection
            @_has_and_belongs_to_many_reflection ||=
              if has_and_belongs_to_many_name
                @subject.reflect_on_association(has_and_belongs_to_many_name)
              end
          end
        end
      end
    end
  end
end
