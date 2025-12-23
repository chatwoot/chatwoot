module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_db_index` matcher tests that the table that backs your model
      # has a specific index.
      #
      # You can specify one column:
      #
      #     class CreateBlogs < ActiveRecord::Migration
      #       def change
      #         create_table :blogs do |t|
      #           t.integer :user_id
      #         end
      #
      #         add_index :blogs, :user_id
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Blog, type: :model do
      #       it { should have_db_index(:user_id) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class BlogTest < ActiveSupport::TestCase
      #       should have_db_index(:user_id)
      #     end
      #
      # Or you can specify a group of columns:
      #
      #     class CreateBlogs < ActiveRecord::Migration
      #       def change
      #         create_table :blogs do |t|
      #           t.integer :user_id
      #           t.string :name
      #         end
      #
      #         add_index :blogs, :user_id, :name
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Blog, type: :model do
      #       it { should have_db_index([:user_id, :name]) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class BlogTest < ActiveSupport::TestCase
      #       should have_db_index([:user_id, :name])
      #     end
      #
      # Finally, if you're using Rails 5 and PostgreSQL, you can also specify an
      # expression:
      #
      #     class CreateLoggedErrors < ActiveRecord::Migration
      #       def change
      #         create_table :logged_errors do |t|
      #           t.string :code
      #           t.jsonb :content
      #         end
      #
      #         add_index :logged_errors, 'lower(code)::text'
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe LoggedError, type: :model do
      #       it { should have_db_index('lower(code)::text') }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class LoggedErrorTest < ActiveSupport::TestCase
      #       should have_db_index('lower(code)::text')
      #     end
      #
      # #### Qualifiers
      #
      # ##### unique
      #
      # Use `unique` to assert that the index is either unique or non-unique:
      #
      #     class CreateBlogs < ActiveRecord::Migration
      #       def change
      #         create_table :blogs do |t|
      #           t.string :domain
      #           t.integer :user_id
      #         end
      #
      #         add_index :blogs, :domain, unique: true
      #         add_index :blogs, :user_id
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Blog, type: :model do
      #       it { should have_db_index(:name).unique }
      #       it { should have_db_index(:name).unique(true) }   # if you want to be explicit
      #       it { should have_db_index(:user_id).unique(false) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class BlogTest < ActiveSupport::TestCase
      #       should have_db_index(:name).unique
      #       should have_db_index(:name).unique(true)   # if you want to be explicit
      #       should have_db_index(:user_id).unique(false)
      #     end
      #
      # @return [HaveDbIndexMatcher]
      #
      def have_db_index(columns)
        HaveDbIndexMatcher.new(columns)
      end

      # @private
      class HaveDbIndexMatcher
        def initialize(columns)
          @expected_columns = normalize_columns_to_array(columns)
          @qualifiers = {}
        end

        def unique(unique = true)
          @qualifiers[:unique] = unique
          self
        end

        def matches?(subject)
          @subject = subject
          index_exists? && correct_unique?
        end

        def failure_message
          message =
            "Expected #{described_table_name} to #{positive_expectation}"

          message <<
            if index_exists?
              ". The index does exist, but #{reason}."
            elsif reason
              ", but #{reason}."
            else
              ', but it does not.'
            end

          Shoulda::Matchers.word_wrap(message)
        end

        def failure_message_when_negated
          Shoulda::Matchers.word_wrap(
            "Expected #{described_table_name} not to " +
            "#{negative_expectation}, but it does.",
          )
        end

        def description
          description = 'have '

          description <<
            if qualifiers.include?(:unique)
              "#{Shoulda::Matchers::Util.a_or_an(index_type)} "
            else
              'an '
            end

          description << 'index on '

          description << inspected_expected_columns
        end

        private

        attr_reader :expected_columns, :qualifiers, :subject, :reason

        def normalize_columns_to_array(columns)
          Array.wrap(columns).map(&:to_s)
        end

        def index_exists?
          !matched_index.nil?
        end

        def correct_unique?
          if qualifiers.include?(:unique)
            if qualifiers[:unique] && !matched_index.unique
              @reason = 'it is not unique'
              false
            elsif !qualifiers[:unique] && matched_index.unique
              @reason = 'it is unique'
              false
            else
              true
            end
          else
            true
          end
        end

        def matched_index
          @_matched_index ||=
            if expected_columns.one?
              actual_indexes.detect do |index|
                Array.wrap(index.columns) == expected_columns
              end
            else
              actual_indexes.detect do |index|
                index.columns == expected_columns
              end
            end
        end

        def actual_indexes
          model.connection.indexes(table_name)
        end

        def described_table_name
          if model
            "the #{table_name} table"
          else
            'a table'
          end
        end

        def table_name
          model.table_name
        end

        def positive_expectation
          if index_exists?
            expectation = "have an index on #{inspected_expected_columns}"

            if qualifiers.include?(:unique)
              expectation << " and for it to be #{index_type}"
            end

            expectation
          else
            description
          end
        end

        def negative_expectation
          description
        end

        def inspected_expected_columns
          if formatted_expected_columns.one?
            formatted_expected_columns.first.inspect
          else
            formatted_expected_columns.inspect
          end
        end

        def index_type
          if qualifiers[:unique]
            'unique'
          else
            'non-unique'
          end
        end

        def formatted_expected_columns
          expected_columns.map do |column|
            if column.match?(/^\w+$/)
              column.to_sym
            else
              column
            end
          end
        end

        def model
          subject&.class
        end
      end
    end
  end
end
