# frozen_string_literal: true

module RuboCop
  module Cop
    module Gemspec
      # Enforce that development dependencies for a gem are specified in
      # `Gemfile`, rather than in the `gemspec` using
      # `add_development_dependency`. Alternatively, using `EnforcedStyle:
      # gemspec`, enforce that all dependencies are specified in `gemspec`,
      # rather than in `Gemfile`.
      #
      # @example EnforcedStyle: Gemfile (default)
      #   # Specify runtime dependencies in your gemspec,
      #   # but all other dependencies in your Gemfile.
      #
      #   # bad
      #   # example.gemspec
      #   s.add_development_dependency "foo"
      #
      #   # good
      #   # Gemfile
      #   gem "foo"
      #
      #   # good
      #   # gems.rb
      #   gem "foo"
      #
      #   # good (with AllowedGems: ["bar"])
      #   # example.gemspec
      #   s.add_development_dependency "bar"
      #
      # @example EnforcedStyle: gems.rb
      #   # Specify runtime dependencies in your gemspec,
      #   # but all other dependencies in your Gemfile.
      #   #
      #   # Identical to `EnforcedStyle: Gemfile`, but with a different error message.
      #   # Rely on Bundler/GemFilename to enforce the use of `Gemfile` vs `gems.rb`.
      #
      #   # bad
      #   # example.gemspec
      #   s.add_development_dependency "foo"
      #
      #   # good
      #   # Gemfile
      #   gem "foo"
      #
      #   # good
      #   # gems.rb
      #   gem "foo"
      #
      #   # good (with AllowedGems: ["bar"])
      #   # example.gemspec
      #   s.add_development_dependency "bar"
      #
      # @example EnforcedStyle: gemspec
      #   # Specify all dependencies in your gemspec.
      #
      #   # bad
      #   # Gemfile
      #   gem "foo"
      #
      #   # good
      #   # example.gemspec
      #   s.add_development_dependency "foo"
      #
      #   # good (with AllowedGems: ["bar"])
      #   # Gemfile
      #   gem "bar"
      #
      class DevelopmentDependencies < Base
        include ConfigurableEnforcedStyle

        MSG = 'Specify development dependencies in %<preferred>s.'
        RESTRICT_ON_SEND = %i[add_development_dependency gem].freeze

        # @!method add_development_dependency?(node)
        def_node_matcher :add_development_dependency?, <<~PATTERN
          (send _ :add_development_dependency (str #forbidden_gem? ...) _? _?)
        PATTERN

        # @!method gem?(node)
        def_node_matcher :gem?, <<~PATTERN
          (send _ :gem (str #forbidden_gem? ...))
        PATTERN

        def on_send(node)
          case style
          when :Gemfile, :'gems.rb'
            add_offense(node) if add_development_dependency?(node)
          when :gemspec
            add_offense(node) if gem?(node)
          end
        end

        private

        def forbidden_gem?(gem_name)
          !cop_config['AllowedGems'].include?(gem_name)
        end

        def message(_range)
          format(MSG, preferred: style)
        end
      end
    end
  end
end
