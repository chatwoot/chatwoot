# frozen_string_literal: true

require_relative "active_record_enumerator"
require_relative "csv_enumerator"

module Sidekiq
  module Job
    module Iterable
      module Enumerators
        # Builds Enumerator object from a given array, using +cursor+ as an offset.
        #
        # @param array [Array]
        # @param cursor [Integer] offset to start iteration from
        #
        # @return [Enumerator]
        #
        # @example
        #   array_enumerator(['build', 'enumerator', 'from', 'any', 'array'], cursor: cursor)
        #
        def array_enumerator(array, cursor:)
          raise ArgumentError, "array must be an Array" unless array.is_a?(Array)

          x = array.each_with_index.drop(cursor || 0)
          x.to_enum { x.size }
        end

        # Builds Enumerator from `ActiveRecord::Relation`.
        # Each Enumerator tick moves the cursor one row forward.
        #
        # @param relation [ActiveRecord::Relation] relation to iterate
        # @param cursor [Object] offset id to start iteration from
        # @param options [Hash] additional options that will be passed to relevant
        #   ActiveRecord batching methods
        #
        # @return [ActiveRecordEnumerator]
        #
        # @example
        #   def build_enumerator(cursor:)
        #     active_record_records_enumerator(User.all, cursor: cursor)
        #   end
        #
        #   def each_iteration(user)
        #     user.notify_about_something
        #   end
        #
        def active_record_records_enumerator(relation, cursor:, **options)
          ActiveRecordEnumerator.new(relation, cursor: cursor, **options).records
        end

        # Builds Enumerator from `ActiveRecord::Relation` and enumerates on batches of records.
        # Each Enumerator tick moves the cursor `:batch_size` rows forward.
        # @see #active_record_records_enumerator
        #
        # @example
        #   def build_enumerator(product_id, cursor:)
        #     active_record_batches_enumerator(
        #       Comment.where(product_id: product_id).select(:id),
        #       cursor: cursor,
        #       batch_size: 100
        #     )
        #   end
        #
        #   def each_iteration(batch_of_comments, product_id)
        #     comment_ids = batch_of_comments.map(&:id)
        #     CommentService.call(comment_ids: comment_ids)
        #   end
        #
        def active_record_batches_enumerator(relation, cursor:, **options)
          ActiveRecordEnumerator.new(relation, cursor: cursor, **options).batches
        end

        # Builds Enumerator from `ActiveRecord::Relation` and enumerates on batches,
        # yielding `ActiveRecord::Relation`s.
        # @see #active_record_records_enumerator
        #
        # @example
        #   def build_enumerator(product_id, cursor:)
        #     active_record_relations_enumerator(
        #       Product.find(product_id).comments,
        #       cursor: cursor,
        #       batch_size: 100,
        #     )
        #   end
        #
        #   def each_iteration(batch_of_comments, product_id)
        #     # batch_of_comments will be a Comment::ActiveRecord_Relation
        #     batch_of_comments.update_all(deleted: true)
        #   end
        #
        def active_record_relations_enumerator(relation, cursor:, **options)
          ActiveRecordEnumerator.new(relation, cursor: cursor, **options).relations
        end

        # Builds Enumerator from a CSV file.
        #
        # @param csv [CSV] an instance of CSV object
        # @param cursor [Integer] offset to start iteration from
        #
        # @example
        #   def build_enumerator(import_id, cursor:)
        #     import = Import.find(import_id)
        #     csv_enumerator(import.csv, cursor: cursor)
        #   end
        #
        #   def each_iteration(csv_row)
        #     # insert csv_row into database
        #   end
        #
        def csv_enumerator(csv, cursor:)
          CsvEnumerator.new(csv).rows(cursor: cursor)
        end

        # Builds Enumerator from a CSV file and enumerates on batches of records.
        #
        # @param csv [CSV] an instance of CSV object
        # @param cursor [Integer] offset to start iteration from
        # @option options :batch_size [Integer] (100) size of the batch
        #
        # @example
        #   def build_enumerator(import_id, cursor:)
        #     import = Import.find(import_id)
        #     csv_batches_enumerator(import.csv, cursor: cursor)
        #   end
        #
        #   def each_iteration(batch_of_csv_rows)
        #     # ...
        #   end
        #
        def csv_batches_enumerator(csv, cursor:, **options)
          CsvEnumerator.new(csv).batches(cursor: cursor, **options)
        end
      end
    end
  end
end
