# frozen_string_literal: true

module Sidekiq
  module Job
    module Iterable
      # @api private
      class CsvEnumerator
        def initialize(csv)
          unless defined?(CSV) && csv.instance_of?(CSV)
            raise ArgumentError, "CsvEnumerator.new takes CSV object"
          end

          @csv = csv
        end

        def rows(cursor:)
          @csv.lazy
            .each_with_index
            .drop(cursor || 0)
            .to_enum { count_of_rows_in_file }
        end

        def batches(cursor:, batch_size: 100)
          @csv.lazy
            .each_slice(batch_size)
            .with_index
            .drop(cursor || 0)
            .to_enum { (count_of_rows_in_file.to_f / batch_size).ceil }
        end

        private

        def count_of_rows_in_file
          filepath = @csv.path
          return unless filepath

          count = IO.popen(["wc", "-l", filepath]) do |out|
            out.read.strip.to_i
          end

          count -= 1 if @csv.headers
          count
        end
      end
    end
  end
end
