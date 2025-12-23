# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Checks that `RUBY_VERSION` constant is not used in gemspec.
      # Using `RUBY_VERSION` is dangerous because value of the
      # constant is determined by `rake release`.
      # It's possible to have dependency based on ruby version used
      # to execute `rake release` and not user's ruby version.
      #
      # @example
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     if RUBY_VERSION >= '3.0'
      #       spec.add_dependency 'gem_a'
      #     else
      #       spec.add_dependency 'gem_b'
      #     end
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.add_dependency 'gem_a'
      #   end
      #
      class RubyVersionGlobalsUsage < Base
        include GemspecHelp

        MSG = 'Do not use `RUBY_VERSION` in gemspec file.'

        # @!method ruby_version?(node)
        def_node_matcher :ruby_version?, '(const {cbase nil?} :RUBY_VERSION)'

        def on_const(node)
          return unless gem_spec_with_ruby_version?(node)

          add_offense(node)
        end

        private

        def gem_spec_with_ruby_version?(node)
          gem_specification(processed_source.ast) && ruby_version?(node)
        end
      end
    end
  end
end
