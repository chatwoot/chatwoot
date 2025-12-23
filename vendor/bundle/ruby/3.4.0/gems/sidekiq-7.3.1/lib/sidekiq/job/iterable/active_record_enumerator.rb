# frozen_string_literal: true

module Sidekiq
  module Job
    module Iterable
      # @api private
      class ActiveRecordEnumerator
        def initialize(relation, cursor: nil, **options)
          @relation = relation
          @cursor = cursor
          @options = options
        end

        def records
          Enumerator.new(-> { @relation.count }) do |yielder|
            @relation.find_each(**@options, start: @cursor) do |record|
              yielder.yield(record, record.id)
            end
          end
        end

        def batches
          Enumerator.new(-> { @relation.count }) do |yielder|
            @relation.find_in_batches(**@options, start: @cursor) do |batch|
              yielder.yield(batch, batch.last.id)
            end
          end
        end

        def relations
          Enumerator.new(-> { relations_size }) do |yielder|
            # Convenience to use :batch_size for all the
            # ActiveRecord batching methods.
            options = @options.dup
            options[:of] ||= options.delete(:batch_size)

            @relation.in_batches(**options, start: @cursor) do |relation|
              last_record = relation.last
              yielder.yield(relation, last_record.id)
            end
          end
        end

        private

        def relations_size
          batch_size = @options[:batch_size] || 1000
          (@relation.count + batch_size - 1) / batch_size # ceiling division
        end
      end
    end
  end
end
