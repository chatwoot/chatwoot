# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # The top-level compiler holding the global state
      # Defers work to its subcompilers
      #
      # Doc on how this fits in the compiling process:
      #   /docs/modules/ROOT/pages/node_pattern.adoc
      class Compiler
        extend SimpleForwardable
        attr_reader :captures, :named_parameters, :positional_parameters, :binding

        def initialize
          @temp_depth = 0 # avoid name clashes between temp variables
          @captures = 0 # number of captures seen
          @positional_parameters = 0 # highest % (param) number seen
          @named_parameters = Set[] # keyword parameters
          @binding = Binding.new # bound variables
          @atom_subcompiler = self.class::AtomSubcompiler.new(self)
        end

        def_delegators :binding, :bind

        def positional_parameter(number)
          @positional_parameters = number if number > @positional_parameters
          "param#{number}"
        end

        def named_parameter(name)
          @named_parameters << name
          name
        end

        # Enumerates `enum` while keeping track of state across
        # union branches (captures and unification).
        def each_union(enum, &block)
          enforce_same_captures(binding.union_bind(enum), &block)
        end

        def compile_as_atom(node)
          @atom_subcompiler.compile(node)
        end

        def compile_as_node_pattern(node, **options)
          self.class::NodePatternSubcompiler.new(self, **options).compile(node)
        end

        def compile_sequence(sequence, var:)
          self.class::SequenceSubcompiler.new(self, sequence: sequence, var: var).compile_sequence
        end

        def parser
          @parser ||= Parser.new
        end

        # Utilities

        def with_temp_variables(*names, &block)
          @temp_depth += 1
          suffix = @temp_depth if @temp_depth > 1
          names = block.parameters.map(&:last) if names.empty?
          names.map! { |name| "#{name}#{suffix}" }
          yield(*names)
        ensure
          @temp_depth -= 1
        end

        def next_capture
          "captures[#{new_capture}]"
        end

        def freeze
          @named_parameters.freeze
          super
        end

        private

        def enforce_same_captures(enum)
          return to_enum __method__, enum unless block_given?

          captures_before = captures_after = nil
          enum.each do |node|
            captures_before ||= @captures
            @captures = captures_before
            yield node
            captures_after ||= @captures
            if captures_after != @captures
              raise Invalid, 'each branch must have same number of captures'
            end
          end
        end

        def new_capture
          @captures
        ensure
          @captures += 1
        end
      end
    end
  end
end
