# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where `attr_reader` and `attr_writer`
      # for the same method can be combined into single `attr_accessor`.
      #
      # @example
      #   # bad
      #   class Foo
      #     attr_reader :bar
      #     attr_writer :bar
      #   end
      #
      #   # good
      #   class Foo
      #     attr_accessor :bar
      #   end
      #
      class BisectedAttrAccessor < Base
        require_relative 'bisected_attr_accessor/macro'

        include RangeHelp
        extend AutoCorrector

        MSG = 'Combine both accessors into `attr_accessor %<name>s`.'

        def on_new_investigation
          @macros_to_rewrite = {}
        end

        def on_class(class_node)
          @macros_to_rewrite[class_node] = Set.new

          find_macros(class_node.body).each_value do |macros|
            bisected = find_bisection(macros)
            next unless bisected.any?

            macros.each do |macro|
              attrs = macro.bisect(*bisected)
              next if attrs.none?

              @macros_to_rewrite[class_node] << macro
              attrs.each { |attr| register_offense(attr) }
            end
          end
        end
        alias on_sclass on_class
        alias on_module on_class

        # Each offending macro is captured and registered in `on_class` but correction
        # happens in `after_class` because a macro might have multiple attributes
        # rewritten from it
        def after_class(class_node)
          @macros_to_rewrite[class_node].each do |macro|
            node = macro.node
            range = range_by_whole_lines(node.source_range, include_final_newline: true)

            correct(range) do |corrector|
              if macro.writer?
                correct_writer(corrector, macro, node, range)
              else
                correct_reader(corrector, macro, node, range)
              end
            end
          end
        end
        alias after_sclass after_class
        alias after_module after_class

        private

        def find_macros(class_def)
          # Find all the macros (`attr_reader`, `attr_writer`, etc.) in the class body
          # and turn them into `Macro` objects so that they can be processed.
          return {} if !class_def || class_def.def_type?

          send_nodes =
            if class_def.send_type?
              [class_def]
            else
              class_def.each_child_node(:send)
            end

          send_nodes.each_with_object([]) do |node, macros|
            macros << Macro.new(node) if Macro.macro?(node)
          end.group_by(&:visibility)
        end

        def find_bisection(macros)
          # Find which attributes are defined in both readers and writers so that they
          # can be replaced with accessors.
          readers, writers = macros.partition(&:reader?)
          readers.flat_map(&:attr_names) & writers.flat_map(&:attr_names)
        end

        def register_offense(attr)
          add_offense(attr, message: format(MSG, name: attr.source))
        end

        def correct_reader(corrector, macro, node, range)
          attr_accessor = "attr_accessor #{macro.bisected_names.join(', ')}\n"

          if macro.all_bisected?
            corrector.replace(range, "#{indent(node)}#{attr_accessor}")
          else
            correction = "#{indent(node)}attr_reader #{macro.rest.join(', ')}"
            corrector.insert_before(node, attr_accessor)
            corrector.replace(node, correction)
          end
        end

        def correct_writer(corrector, macro, node, range)
          if macro.all_bisected?
            corrector.remove(range)
          else
            correction = "attr_writer #{macro.rest.join(', ')}"
            corrector.replace(node, correction)
          end
        end
      end
    end
  end
end
