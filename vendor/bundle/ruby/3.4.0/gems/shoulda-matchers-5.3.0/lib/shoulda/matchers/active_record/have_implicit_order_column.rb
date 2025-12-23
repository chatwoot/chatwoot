module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_implicit_order_column` matcher tests that the model has `implicit_order_column`
      # assigned to one of the table columns. (Rails 6+ only)
      #
      #     class Product < ApplicationRecord
      #       self.implicit_order_column = :created_at
      #     end
      #
      #     # RSpec
      #     RSpec.describe Product, type: :model do
      #       it { should have_implicit_order_column(:created_at) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class ProductTest < ActiveSupport::TestCase
      #       should have_implicit_order_column(:created_at)
      #     end
      #
      # @return [HaveImplicitOrderColumnMatcher]
      #
      if RailsShim.active_record_gte_6?
        def have_implicit_order_column(column_name)
          HaveImplicitOrderColumnMatcher.new(column_name)
        end
      end

      # @private
      class HaveImplicitOrderColumnMatcher
        attr_reader :failure_message

        def initialize(column_name)
          @column_name = column_name
        end

        def matches?(subject)
          @subject = subject
          check_column_exists!
          check_implicit_order_column_matches!
          true
        rescue SecondaryCheckFailedError => e
          @failure_message = Shoulda::Matchers.word_wrap(
            "Expected #{model.name} to #{expectation}, " +
            "but that could not be proved: #{e.message}.",
          )
          false
        rescue PrimaryCheckFailedError => e
          @failure_message = Shoulda::Matchers.word_wrap(
            "Expected #{model.name} to #{expectation}, but #{e.message}.",
          )
          false
        end

        def failure_message_when_negated
          Shoulda::Matchers.word_wrap(
            "Expected #{model.name} not to #{expectation}, but it did.",
          )
        end

        def description
          expectation
        end

        private

        attr_reader :column_name, :subject

        def check_column_exists!
          matcher = HaveDbColumnMatcher.new(column_name)

          if !matcher.matches?(@subject)
            raise SecondaryCheckFailedError.new(
              "The :#{model.table_name} table does not have a " +
              ":#{column_name} column",
            )
          end
        end

        def check_implicit_order_column_matches!
          if model.implicit_order_column.to_s != column_name.to_s
            message =
              if model.implicit_order_column.nil?
                'implicit_order_column is not set'
              else
                "it is :#{model.implicit_order_column}"
              end

            raise PrimaryCheckFailedError.new(message)
          end
        end

        def model
          subject.class
        end

        def expectation
          "have an implicit_order_column of :#{column_name}"
        end

        class SecondaryCheckFailedError < StandardError; end
        class PrimaryCheckFailedError < StandardError; end
      end
    end
  end
end
