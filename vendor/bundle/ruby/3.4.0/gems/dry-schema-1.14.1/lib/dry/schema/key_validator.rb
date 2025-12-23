# frozen_string_literal: true

require "dry/initializer"
require "dry/schema/constants"

module Dry
  module Schema
    # @api private
    class KeyValidator
      extend ::Dry::Initializer

      INDEX_REGEX = /\[\d+\]/
      DIGIT_REGEX = /\A\d+\z/
      BRACKETS = "[]"

      # @api private
      option :key_map

      # @api private
      def call(result)
        input = result.to_h

        input_paths = key_paths(input)
        key_paths = key_map.to_dot_notation.sort

        input_paths.each do |path|
          error_path = validate_path(key_paths, path)

          next unless error_path

          result.add_error([:unexpected_key, [error_path, input]])
        end

        result
      end

      private

      # @api private
      def validate_path(key_paths, path)
        if path[INDEX_REGEX]
          key = path.gsub(INDEX_REGEX, BRACKETS)
          if none_key_paths_match?(key_paths, key)
            arr = path.gsub(INDEX_REGEX) { ".#{_1[1]}" }
            arr.split(DOT).map { DIGIT_REGEX.match?(_1) ? Integer(_1, 10) : _1.to_sym }
          end
        elsif none_key_paths_match?(key_paths, path)
          path
        end
      end

      # @api private
      def none_key_paths_match?(key_paths, path)
        !any_key_paths_match?(key_paths, path)
      end

      # @api private
      def any_key_paths_match?(key_paths, path)
        find_path(key_paths, path, false) ||
          find_path(key_paths, path + DOT, true) ||
          find_path(key_paths, path + BRACKETS, true)
      end

      # @api private
      def find_path(key_paths, path, prefix_match)
        key = key_paths.bsearch { |key_path| key_path >= path }
        prefix_match ? key&.start_with?(path) : key == path
      end

      # @api private
      def key_paths(hash)
        hash.flat_map { |key, value|
          case value
          when ::Hash
            if value.empty?
              [key.to_s]
            else
              [key].product(key_paths(hash[key])).map { _1.join(DOT) }
            end
          when ::Array
            hashes_or_arrays = hashes_or_arrays(value)

            if hashes_or_arrays.empty?
              [key.to_s]
            else
              hashes_or_arrays.flat_map.with_index { |el, idx|
                key_paths(el).map { ["#{key}[#{idx}]", *_1].join(DOT) }
              }
            end
          else
            key.to_s
          end
        }
      end

      # @api private
      def hashes_or_arrays(xs)
        xs.select { |x|
          (x.is_a?(::Array) || x.is_a?(::Hash)) && !x.empty?
        }
      end
    end
  end
end
