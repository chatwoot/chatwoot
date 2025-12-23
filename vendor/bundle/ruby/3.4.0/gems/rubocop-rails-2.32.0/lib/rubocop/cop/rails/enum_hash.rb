# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for enums written with array syntax.
      #
      # When using array syntax, adding an element in a
      # position other than the last causes all previous
      # definitions to shift. Explicitly specifying the
      # value for each key prevents this from happening.
      #
      # @example
      #   # bad
      #   enum :status, [:active, :archived]
      #
      #   # good
      #   enum :status, { active: 0, archived: 1 }
      #
      #   # bad
      #   enum status: [:active, :archived]
      #
      #   # good
      #   enum status: { active: 0, archived: 1 }
      #
      class EnumHash < Base
        extend AutoCorrector

        MSG = 'Enum defined as an array found in `%<enum>s` enum declaration. Use hash syntax instead.'
        RESTRICT_ON_SEND = %i[enum].freeze

        def_node_matcher :enum_with_array?, <<~PATTERN
          (send nil? :enum $_ ${array} ...)
        PATTERN

        def_node_matcher :enum_with_old_syntax?, <<~PATTERN
          (send nil? :enum (hash $...))
        PATTERN

        def_node_matcher :array_pair?, <<~PATTERN
          (pair $_ $array)
        PATTERN

        def on_send(node)
          target_rails_version >= 7.0 && enum_with_array?(node) do |key, array|
            add_offense(array, message: message(key)) do |corrector|
              corrector.replace(array, build_hash(array))
            end
          end

          enum_with_old_syntax?(node) do |pairs|
            pairs.each do |pair|
              key, array = array_pair?(pair)
              next unless key

              add_offense(array, message: message(key)) do |corrector|
                corrector.replace(array, build_hash(array))
              end
            end
          end
        end

        private

        def message(key)
          format(MSG, enum: enum_name(key))
        end

        def enum_name(key)
          case key.type
          when :sym, :str
            key.value
          else
            key.source
          end
        end

        def source(elem)
          case elem.type
          when :str
            elem.value.dump
          when :sym
            elem.value.inspect
          else
            elem.source
          end
        end

        def build_hash(array)
          hash = array.children.each_with_index.map do |elem, index|
            "#{source(elem)} => #{index}"
          end.join(', ')
          "{#{hash}}"
        end
      end
    end
  end
end
