# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use of `$stdout/$stderr/$stdin` instead of `STDOUT/STDERR/STDIN`.
      # `STDOUT/STDERR/STDIN` are constants, and while you can actually
      # reassign (possibly to redirect some stream) constants in Ruby, you'll get
      # an interpreter warning if you do so.
      #
      # Additionally, `$stdout/$stderr/$stdin` can safely be accessed in a Ractor because they
      # are ractor-local, while `STDOUT/STDERR/STDIN` will raise `Ractor::IsolationError`.
      #
      # @safety
      #   Autocorrection is unsafe because `STDOUT` and `$stdout` may point to different
      #   objects, for example.
      #
      # @example
      #   # bad
      #   STDOUT.puts('hello')
      #
      #   hash = { out: STDOUT, key: value }
      #
      #   def m(out = STDOUT)
      #     out.puts('hello')
      #   end
      #
      #   # good
      #   $stdout.puts('hello')
      #
      #   hash = { out: $stdout, key: value }
      #
      #   def m(out = $stdout)
      #     out.puts('hello')
      #   end
      #
      class GlobalStdStream < Base
        extend AutoCorrector

        MSG = 'Use `%<gvar_name>s` instead of `%<const_name>s`.'

        STD_STREAMS = %i[STDIN STDOUT STDERR].to_set.freeze

        # @!method const_to_gvar_assignment?(node, name)
        def_node_matcher :const_to_gvar_assignment?, <<~PATTERN
          (gvasgn %1 (const nil? _))
        PATTERN

        def on_const(node)
          return if namespaced?(node)

          const_name = node.short_name
          return unless STD_STREAMS.include?(const_name)

          gvar_name = gvar_name(const_name).to_sym
          return if const_to_gvar_assignment?(node.parent, gvar_name)

          add_offense(node, message: message(const_name)) do |corrector|
            corrector.replace(node, gvar_name)
          end
        end

        private

        def message(const_name)
          format(MSG, gvar_name: gvar_name(const_name), const_name: const_name)
        end

        def namespaced?(node)
          !node.namespace.nil? && (node.relative? || !node.namespace.cbase_type?)
        end

        def gvar_name(const_name)
          "$#{const_name.to_s.downcase}"
        end
      end
    end
  end
end
