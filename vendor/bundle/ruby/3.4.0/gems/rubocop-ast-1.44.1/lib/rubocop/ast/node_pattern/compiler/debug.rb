# frozen_string_literal: true

require 'rainbow'

module RuboCop
  module AST
    class NodePattern
      class Compiler
        # Variant of the Compiler with tracing information for nodes
        class Debug < Compiler
          # Compiled node pattern requires a named parameter `trace`,
          # which should be an instance of this class
          class Trace
            def initialize
              @visit = {}
            end

            def enter(node_id)
              @visit[node_id] = false
              true
            end

            def success(node_id)
              @visit[node_id] = true
            end

            # return nil (not visited), false (not matched) or true (matched)
            def matched?(node_id)
              @visit[node_id]
            end
          end

          attr_reader :node_ids

          # @api private
          class Colorizer
            COLOR_SCHEME = {
              not_visitable: :lightseagreen,
              nil => :yellow,
              false => :red,
              true => :green
            }.freeze

            # Result of a NodePattern run against a particular AST
            # Consider constructor is private
            Result = Struct.new(:colorizer, :trace, :returned, :ruby_ast) do
              # @return [String] a Rainbow colorized version of ruby
              def colorize(color_scheme = COLOR_SCHEME)
                map = color_map(color_scheme)
                ast.source_range.source_buffer.source.chars.map.with_index do |char, i|
                  Rainbow(char).color(map[i])
                end.join
              end

              # @return [Hash] a map for {character_position => color}
              def color_map(color_scheme = COLOR_SCHEME)
                @color_map ||=
                  match_map
                  .transform_values { |matched| color_scheme.fetch(matched) }
                  .map { |node, color| color_map_for(node, color) }
                  .inject(:merge)
                  .tap { |h| h.default = color_scheme.fetch(:not_visitable) }
              end

              # @return [Hash] a map for {node => matched?}, depth-first
              def match_map
                @match_map ||=
                  ast
                  .each_node
                  .to_h { |node| [node, matched?(node)] }
              end

              # @return a value of `Trace#matched?` or `:not_visitable`
              def matched?(node)
                id = colorizer.compiler.node_ids.fetch(node) { return :not_visitable }
                trace.matched?(id)
              end

              private

              def color_map_for(node, color)
                return {} unless (range = node.loc&.expression)

                range.to_a.to_h { |char| [char, color] }
              end

              def ast
                colorizer.node_pattern.ast
              end
            end

            Compiler = Debug

            attr_reader :pattern, :compiler, :node_pattern

            def initialize(pattern, compiler: self.class::Compiler.new)
              @pattern = pattern
              @compiler = compiler
              @node_pattern = ::RuboCop::AST::NodePattern.new(pattern, compiler: @compiler)
            end

            # @return [Node] the Ruby AST
            def test(ruby, trace: self.class::Compiler::Trace.new)
              ruby = ruby_ast(ruby) if ruby.is_a?(String)
              returned = @node_pattern.as_lambda.call(ruby, trace: trace)
              self.class::Result.new(self, trace, returned, ruby)
            end

            private

            def ruby_ast(ruby)
              ProcessedSource.new(ruby, RUBY_VERSION.to_f, '(ruby)').ast
            end
          end

          def initialize
            super
            @node_ids = Hash.new { |h, k| h[k] = h.size }.compare_by_identity
          end

          def named_parameters
            super << :trace
          end

          def parser
            @parser ||= Parser::WithMeta.new
          end

          def_delegators :parser, :comments, :tokens

          # @api private
          module InstrumentationSubcompiler
            def do_compile
              "#{tracer(:enter)} && #{super} && #{tracer(:success)}"
            end

            private

            def tracer(kind)
              "trace.#{kind}(#{node_id})"
            end

            def node_id
              compiler.node_ids[node]
            end
          end

          # @api private
          class NodePatternSubcompiler < Compiler::NodePatternSubcompiler
            include InstrumentationSubcompiler
          end

          # @api private
          class SequenceSubcompiler < Compiler::SequenceSubcompiler
            include InstrumentationSubcompiler
          end
        end
      end
    end
  end
end
