module Shoulda
  module Matchers
    module ActiveRecord
      # The `have_db_column` matcher tests that the table that backs your model
      # has a specific column.
      #
      #     class CreatePhones < ActiveRecord::Migration
      #       def change
      #         create_table :phones do |t|
      #           t.string :supported_ios_version
      #         end
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Phone, type: :model do
      #       it { should have_db_column(:supported_ios_version) }
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PhoneTest < ActiveSupport::TestCase
      #       should have_db_column(:supported_ios_version)
      #     end
      #
      # #### Qualifiers
      #
      # ##### of_type
      #
      # Use `of_type` to assert that a column is defined as a certain type.
      #
      #     class CreatePhones < ActiveRecord::Migration
      #       def change
      #         create_table :phones do |t|
      #           t.decimal :camera_aperture
      #         end
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Phone, type: :model do
      #       it do
      #         should have_db_column(:camera_aperture).of_type(:decimal)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PhoneTest < ActiveSupport::TestCase
      #       should have_db_column(:camera_aperture).of_type(:decimal)
      #     end
      #
      # ##### with_options
      #
      # Use `with_options` to assert that a column has been defined with
      # certain options (`:precision`, `:limit`, `:default`, `:null`, `:scale`,
      # `:primary` or `:array`).
      #
      #     class CreatePhones < ActiveRecord::Migration
      #       def change
      #         create_table :phones do |t|
      #           t.decimal :camera_aperture, precision: 1, null: false
      #         end
      #       end
      #     end
      #
      #     # RSpec
      #     RSpec.describe Phone, type: :model do
      #       it do
      #         should have_db_column(:camera_aperture).
      #           with_options(precision: 1, null: false)
      #       end
      #     end
      #
      #     # Minitest (Shoulda)
      #     class PhoneTest < ActiveSupport::TestCase
      #       should have_db_column(:camera_aperture).
      #         with_options(precision: 1, null: false)
      #     end
      #
      # @return [HaveDbColumnMatcher]
      #
      def have_db_column(column)
        HaveDbColumnMatcher.new(column)
      end

      # @private
      class HaveDbColumnMatcher
        OPTIONS = %i(precision limit default null scale primary array).freeze

        def initialize(column)
          @column = column
          @options = {}
        end

        def of_type(column_type)
          @options[:column_type] = column_type
          self
        end

        def with_options(opts = {})
          validate_options(opts)
          OPTIONS.each do |attribute|
            if opts.key?(attribute.to_sym)
              @options[attribute.to_sym] = opts[attribute.to_sym]
            end
          end
          self
        end

        def matches?(subject)
          @subject = subject
          column_exists? &&
            correct_column_type? &&
            correct_precision? &&
            correct_limit? &&
            correct_default? &&
            correct_null? &&
            correct_scale? &&
            correct_primary? &&
            correct_array?
        end

        def failure_message
          "Expected #{expectation} (#{@missing})"
        end

        def failure_message_when_negated
          "Did not expect #{expectation}"
        end

        def description
          desc = "have db column named #{@column}"
          if @options.key?(:column_type)
            desc << " of type #{@options[:column_type]}"
          end
          if @options.key?(:precision)
            desc << " of precision #{@options[:precision]}"
          end
          desc << " of limit #{@options[:limit]}" if @options.key?(:limit)
          desc << " of default #{@options[:default]}" if @options.key?(:default)
          desc << " of null #{@options[:null]}" if @options.key?(:null)
          desc << " of primary #{@options[:primary]}" if @options.key?(:primary)
          desc << " of scale #{@options[:scale]}" if @options.key?(:scale)
          desc
        end

        protected

        def validate_options(opts)
          invalid_options = opts.keys.map(&:to_sym) - OPTIONS
          if invalid_options.any?
            raise(
              ArgumentError,
              "Unknown option(s): #{invalid_options.map(&:inspect).join(', ')}",
            )
          end
        end

        def column_exists?
          if model_class.column_names.include?(@column.to_s)
            true
          else
            @missing =
              "#{model_class} does not have a db column named #{@column}."
            false
          end
        end

        def correct_column_type?
          return true unless @options.key?(:column_type)

          if matched_column.type.to_s == @options[:column_type].to_s
            true
          else
            @missing =
              "#{model_class} has a db column named #{@column} " <<
              "of type #{matched_column.type}, not #{@options[:column_type]}."
            false
          end
        end

        def correct_precision?
          return true unless @options.key?(:precision)

          if matched_column.precision.to_s == @options[:precision].to_s
            true
          else
            @missing = "#{model_class} has a db column named #{@column} " <<
                       "of precision #{matched_column.precision}, " <<
                       "not #{@options[:precision]}."
            false
          end
        end

        def correct_limit?
          return true unless @options.key?(:limit)

          if matched_column.limit.to_s == @options[:limit].to_s
            true
          else
            @missing = "#{model_class} has a db column named #{@column} " <<
                       "of limit #{matched_column.limit}, " <<
                       "not #{@options[:limit]}."
            false
          end
        end

        def correct_default?
          return true unless @options.key?(:default)

          if matched_column.type_cast_default.to_s == @options[:default].to_s
            true
          else
            @missing = "#{model_class} has a db column named #{@column} " <<
                       "of default #{matched_column.type_cast_default}, " <<
                       "not #{@options[:default]}."
            false
          end
        end

        def correct_null?
          return true unless @options.key?(:null)

          if matched_column.null.to_s == @options[:null].to_s
            true
          else
            @missing = "#{model_class} has a db column named #{@column} " <<
                       "of null #{matched_column.null}, " <<
                       "not #{@options[:null]}."
            false
          end
        end

        def correct_scale?
          return true unless @options.key?(:scale)

          if actual_scale.to_s == @options[:scale].to_s
            true
          else
            @missing = "#{model_class} has a db column named #{@column} "
            @missing << "of scale #{actual_scale}, not #{@options[:scale]}."
            false
          end
        end

        def correct_primary?
          return true unless @options.key?(:primary)

          if matched_column.primary? == @options[:primary]
            true
          else
            @missing = "#{model_class} has a db column named #{@column} "
            @missing <<
              if @options[:primary]
                'that is not primary, but should be'
              else
                'that is primary, but should not be'
              end
            false
          end
        end

        def correct_array?
          return true unless @options.key?(:array)

          if matched_column.array? == @options[:array]
            true
          else
            @missing = "#{model_class} has a db column named #{@column} "
            @missing <<
              if @options[:primary]
                'that is not array, but should be'
              else
                'that is array, but should not be'
              end
            false
          end
        end

        def matched_column
          @_matched_column ||= begin
            column = model_class.columns.detect do |each|
              each.name == @column.to_s
            end
            DecoratedColumn.new(model_class, column)
          end
        end

        def model_class
          @subject.class
        end

        def actual_scale
          matched_column.scale
        end

        def actual_primary?
          model_class.primary_key == matched_column.name
        end

        def expectation
          "#{model_class.name} to #{description}"
        end

        # @private
        class DecoratedColumn < SimpleDelegator
          def initialize(model, column)
            @model = model
            super(column)
          end

          def type_cast_default
            model.column_defaults[name]
          end

          def primary?
            model.primary_key == name
          end

          protected

          attr_reader :model
        end
      end
    end
  end
end
