# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Base class for subcompilers
        # Implements visitor pattern
        #
        # Doc on how this fits in the compiling process:
        #   /docs/modules/ROOT/pages/node_pattern.adoc
        class Subcompiler
          attr_reader :compiler

          def initialize(compiler)
            @compiler = compiler
            @node = nil
          end

          def compile(node)
            prev = @node
            @node = node
            do_compile
          ensure
            @node = prev
          end

          # @api private

          private

          attr_reader :node

          def do_compile
            send(self.class.registry.fetch(node.type, :visit_other_type))
          end

          @registry = {}
          class << self
            attr_reader :registry

            def method_added(method)
              @registry[Regexp.last_match(1).to_sym] = method if method =~ /^visit_(.*)/
              super
            end

            def inherited(base)
              us = self
              base.class_eval { @registry = us.registry.dup }
              super
            end
          end
        end
      end
    end
  end
end
