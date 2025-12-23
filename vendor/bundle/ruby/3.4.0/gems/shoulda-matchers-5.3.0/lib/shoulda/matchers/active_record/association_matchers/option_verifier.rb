module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class OptionVerifier
          delegate :reflection, to: :reflector

          DEFAULT_VALUE_OF_OPTIONS = {
            has_many: {
              validate: true,
            },
          }.freeze
          RELATION_OPTIONS = [:conditions, :order].freeze

          def initialize(reflector)
            @reflector = reflector
          end

          def correct_for_string?(name, expected_value)
            correct_for?(:string, name, expected_value)
          end

          def correct_for_boolean?(name, expected_value)
            correct_for?(:boolean, name, expected_value)
          end

          def correct_for_hash?(name, expected_value)
            correct_for?(:hash, name, expected_value)
          end

          def correct_for_constant?(name, expected_unresolved_value)
            correct_for?(:constant, name, expected_unresolved_value)
          end

          def correct_for_relation_clause?(name, expected_value)
            correct_for?(:relation_clause, name, expected_value)
          end

          def correct_for?(*args)
            expected_value, name, type = args.reverse

            if expected_value.nil?
              true
            else
              type_cast_expected_value = type_cast(
                type,
                expected_value_for(type, name, expected_value),
              )
              actual_value = type_cast(type, actual_value_for(name))
              type_cast_expected_value == actual_value
            end
          end

          def actual_value_for(name)
            if RELATION_OPTIONS.include?(name)
              actual_value_for_relation_clause(name)
            else
              method_name = "actual_value_for_#{name}"
              if respond_to?(method_name, true)
                __send__(method_name)
              else
                actual_value_for_option(name)
              end
            end
          end

          protected

          attr_reader :reflector

          def type_cast(type, value)
            case type
            when :string, :relation_clause
              value.to_s
            when :boolean
              !!value
            when :hash
              Hash(value).stringify_keys
            else
              value
            end
          end

          def expected_value_for(type, name, value)
            if RELATION_OPTIONS.include?(name)
              expected_value_for_relation_clause(name, value)
            elsif type == :constant
              expected_value_for_constant(value)
            else
              value
            end
          end

          def expected_value_for_relation_clause(name, value)
            relation = reflector.build_relation_with_clause(name, value)
            reflector.extract_relation_clause_from(relation, name)
          end

          def expected_value_for_constant(name)
            namespace = Shoulda::Matchers::Util.deconstantize(
              reflector.model_class.to_s,
            )

            ["#{namespace}::#{name}", name].each do |path|
              constant = Shoulda::Matchers::Util.safe_constantize(path)

              if constant
                return constant
              end
            end
          end

          def actual_value_for_relation_clause(name)
            reflector.extract_relation_clause_from(
              reflector.association_relation,
              name,
            )
          end

          def actual_value_for_class_name
            reflector.associated_class
          end

          def actual_value_for_option(name)
            option_value = reflection.options[name]

            if option_value.nil?
              DEFAULT_VALUE_OF_OPTIONS.dig(reflection.macro, name)
            else
              option_value
            end
          end
        end
      end
    end
  end
end
