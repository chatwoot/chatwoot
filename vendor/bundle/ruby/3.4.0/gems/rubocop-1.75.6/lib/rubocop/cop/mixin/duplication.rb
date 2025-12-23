# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for dealing with duplication.
    module Duplication
      private

      # Whether the `collection` contains any duplicates.
      #
      # @param [Array] collection an array to check for duplicates
      # @return [Boolean] whether the array contains any duplicates
      def duplicates?(collection)
        collection.size > 1 && collection.size > collection.uniq.size
      end

      # Returns all duplicates, including the first instance of the duplicated
      # elements.
      #
      # @param [Array] collection an array to return duplicates for
      # @return [Array] all the duplicates
      def duplicates(collection)
        grouped_duplicates(collection).flatten
      end

      # Returns the consecutive duplicates, leaving out the first instance of
      # the duplicated elements.
      #
      # @param [Array] collection an array to return consecutive duplicates for
      # @return [Array] the consecutive duplicates
      def consecutive_duplicates(collection)
        grouped_duplicates(collection).flat_map { |items| items[1..] }
      end

      # Returns a hash of grouped duplicates. The key will be the first
      # instance of the element, and  the value an `array` of the initial
      # element and all duplicate instances.
      #
      # @param [Array] collection an array to group duplicates for
      # @return [Array] the grouped duplicates
      def grouped_duplicates(collection)
        collection.group_by { |item| item }.values.reject(&:one?)
      end
    end
  end
end
