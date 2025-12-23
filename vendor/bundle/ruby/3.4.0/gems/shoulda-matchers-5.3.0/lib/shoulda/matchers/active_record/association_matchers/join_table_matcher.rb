module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class JoinTableMatcher
          attr_reader :failure_message

          alias :missing_option :failure_message

          delegate :model_class, :join_table_name, :associated_class, :options,
            :name, :option_verifier, to: :association_matcher

          delegate :connection, to: :model_class

          def initialize(association_matcher, reflector)
            @association_matcher = association_matcher
            @reflector = reflector
          end

          def matches?(_subject)
            join_table_option_correct? &&
              join_table_exists? &&
              join_table_has_correct_columns?
          end

          def join_table_option_correct?
            if options.key?(:join_table_name)
              if option_verifier.correct_for_string?(
                :join_table,
                options[:join_table_name],
              )
                true
              else
                @failure_message = "#{name} should use"\
                  " #{options[:join_table_name].inspect} for :join_table option"
                false
              end
            else
              true
            end
          end

          def join_table_exists?
            if connection.data_sources.
                include?(join_table_name.to_s)
              true
            else
              @failure_message = missing_table_message
              false
            end
          end

          def join_table_has_correct_columns?
            if missing_columns.empty?
              true
            else
              @failure_message = missing_columns_message
              false
            end
          end

          protected

          attr_reader :association_matcher, :reflector

          private

          delegate :foreign_key, :association_foreign_key, to: :reflector

          def missing_columns
            @_missing_columns ||= expected_join_table_columns.reject do |key|
              actual_join_table_columns.include?(key.to_s)
            end
          end

          def expected_join_table_columns
            [foreign_key, association_foreign_key]
          end

          def actual_join_table_columns
            connection.columns(join_table_name).map(&:name)
          end

          def missing_table_message
            "join table #{join_table_name} doesn't exist"
          end

          def missing_columns_message
            missing = missing_columns.join(', ')
            "join table #{join_table_name} missing #{column_label}: #{missing}"
          end

          def column_label
            if missing_columns.count > 1
              'columns'
            else
              'column'
            end
          end
        end
      end
    end
  end
end
