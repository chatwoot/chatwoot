# frozen_string_literal: true

#
# This module provides methods to diff two hash, patch and unpatch hash
#
module Hashdiff
  # Apply patch to object
  #
  # @param [Hash, Array] obj the object to be patched, can be an Array or a Hash
  # @param [Array] changes e.g. [[ '+', 'a.b', '45' ], [ '-', 'a.c', '5' ], [ '~', 'a.x', '45', '63']]
  # @param [Hash] options supports following keys:
  #   * :delimiter (String) ['.'] delimiter string for representing nested keys in changes array
  #
  # @return the object after patch
  #
  # @since 0.0.1
  def self.patch!(obj, changes, options = {})
    delimiter = options[:delimiter] || '.'

    changes.each do |change|
      parts = change[1]
      parts = decode_property_path(parts, delimiter) unless parts.is_a?(Array)

      last_part = parts.last

      parent_node = node(obj, parts[0, parts.size - 1])

      if change[0] == '+'
        if parent_node.is_a?(Array)
          parent_node.insert(last_part, change[2])
        else
          parent_node[last_part] = change[2]
        end
      elsif change[0] == '-'
        if parent_node.is_a?(Array)
          parent_node.delete_at(last_part)
        else
          parent_node.delete(last_part)
        end
      elsif change[0] == '~'
        parent_node[last_part] = change[3]
      end
    end

    obj
  end

  # Unpatch an object
  #
  # @param [Hash, Array] obj the object to be unpatched, can be an Array or a Hash
  # @param [Array] changes e.g. [[ '+', 'a.b', '45' ], [ '-', 'a.c', '5' ], [ '~', 'a.x', '45', '63']]
  # @param [Hash] options supports following keys:
  #   * :delimiter (String) ['.'] delimiter string for representing nested keys in changes array
  #
  # @return the object after unpatch
  #
  # @since 0.0.1
  def self.unpatch!(obj, changes, options = {})
    delimiter = options[:delimiter] || '.'

    changes.reverse_each do |change|
      parts = change[1]
      parts = decode_property_path(parts, delimiter) unless parts.is_a?(Array)

      last_part = parts.last

      parent_node = node(obj, parts[0, parts.size - 1])

      if change[0] == '+'
        if parent_node.is_a?(Array)
          parent_node.delete_at(last_part)
        else
          parent_node.delete(last_part)
        end
      elsif change[0] == '-'
        if parent_node.is_a?(Array)
          parent_node.insert(last_part, change[2])
        else
          parent_node[last_part] = change[2]
        end
      elsif change[0] == '~'
        parent_node[last_part] = change[2]
      end
    end

    obj
  end
end
