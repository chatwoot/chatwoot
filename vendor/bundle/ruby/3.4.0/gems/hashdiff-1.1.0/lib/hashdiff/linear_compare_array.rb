# frozen_string_literal: true

module Hashdiff
  # @private
  #
  # Used to compare arrays in a linear complexity, which produces longer diffs
  # than using the lcs algorithm but is considerably faster
  class LinearCompareArray
    def self.call(old_array, new_array, options = {})
      instance = new(old_array, new_array, options)
      instance.call
    end

    def call
      return [] if old_array.empty? && new_array.empty?

      self.old_index = 0
      self.new_index = 0
      # by comparing the array lengths we can expect that a number of items
      # are either added or removed
      self.expected_additions = new_array.length - old_array.length

      loop do
        if extra_items_in_old_array?
          append_deletion(old_array[old_index], old_index)
        elsif extra_items_in_new_array?
          append_addition(new_array[new_index], new_index)
        else
          compare_at_index
        end

        self.old_index = old_index + 1
        self.new_index = new_index + 1
        break if iterated_through_both_arrays?
      end

      changes
    end

    private

    attr_reader :old_array, :new_array, :options, :additions, :deletions, :differences
    attr_accessor :old_index, :new_index, :expected_additions

    def initialize(old_array, new_array, options)
      @old_array = old_array
      @new_array = new_array
      @options = { prefix: '' }.merge!(options)

      @additions = []
      @deletions = []
      @differences = []
    end

    def extra_items_in_old_array?
      old_index < old_array.length && new_index >= new_array.length
    end

    def extra_items_in_new_array?
      new_index < new_array.length && old_index >= old_array.length
    end

    def iterated_through_both_arrays?
      old_index >= old_array.length && new_index >= new_array.length
    end

    def compare_at_index
      difference = item_difference(old_array[old_index], new_array[new_index], old_index)
      return if difference.empty?

      index_after_additions = index_of_match_after_additions
      append_addititions_before_match(index_after_additions)

      index_after_deletions = index_of_match_after_deletions
      append_deletions_before_match(index_after_deletions)

      match = index_after_additions || index_after_deletions

      append_differences(difference) unless match
    end

    def item_difference(old_item, new_item, item_index)
      prefix = Hashdiff.prefix_append_array_index(options[:prefix], item_index, options)
      Hashdiff.diff(old_item, new_item, options.merge(prefix: prefix))
    end

    # look ahead in the new array to see if the current item appears later
    # thereby having new items added
    def index_of_match_after_additions
      return unless expected_additions > 0

      (1..expected_additions).each do |i|
        next_difference = item_difference(
          old_array[old_index],
          new_array[new_index + i],
          old_index
        )

        return new_index + i if next_difference.empty?
      end

      nil
    end

    # look ahead in the old array to see if the current item appears later
    # thereby having items removed
    def index_of_match_after_deletions
      return unless expected_additions < 0

      (1..(expected_additions.abs)).each do |i|
        next_difference = item_difference(
          old_array[old_index + i],
          new_array[new_index],
          old_index
        )

        return old_index + i if next_difference.empty?
      end

      nil
    end

    def append_addititions_before_match(match_index)
      return unless match_index

      (new_index...match_index).each { |i| append_addition(new_array[i], i) }
      self.expected_additions = expected_additions - (match_index - new_index)
      self.new_index = match_index
    end

    def append_deletions_before_match(match_index)
      return unless match_index

      (old_index...match_index).each { |i| append_deletion(old_array[i], i) }
      self.expected_additions = expected_additions + (match_index - new_index)
      self.old_index = match_index
    end

    def append_addition(item, index)
      key = Hashdiff.prefix_append_array_index(options[:prefix], index, options)
      additions << ['+', key, item]
    end

    def append_deletion(item, index)
      key = Hashdiff.prefix_append_array_index(options[:prefix], index, options)
      deletions << ['-', key, item]
    end

    def append_differences(difference)
      differences.concat(difference)
    end

    def changes
      # this algorithm only allows there to be additions or deletions
      # deletions are reverse so they don't change the index of earlier items
      differences + additions + deletions.reverse
    end
  end
end
