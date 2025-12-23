# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # Each gem in the Gemfile should have a comment explaining
      # its purpose in the project, or the reason for its version
      # or source.
      #
      # The optional "OnlyFor" configuration array
      # can be used to only register offenses when the gems
      # use certain options or have version specifiers.
      #
      # When "version_specifiers" is included, a comment
      # will be enforced if the gem has any version specifier.
      #
      # When "restrictive_version_specifiers" is included, a comment
      # will be enforced if the gem has a version specifier that
      # holds back the version of the gem.
      #
      # For any other value in the array, a comment will be enforced for
      # a gem if an option by the same name is present.
      # A useful use case is to enforce a comment when using
      # options that change the source of a gem:
      #
      # - `bitbucket`
      # - `gist`
      # - `git`
      # - `github`
      # - `source`
      #
      # For a full list of options supported by bundler,
      # see https://bundler.io/man/gemfile.5.html
      # .
      #
      # @example OnlyFor: [] (default)
      #   # bad
      #
      #   gem 'foo'
      #
      #   # good
      #
      #   # Helpers for the foo things.
      #   gem 'foo'
      #
      # @example OnlyFor: ['version_specifiers']
      #   # bad
      #
      #   gem 'foo', '< 2.1'
      #
      #   # good
      #
      #   # Version 2.1 introduces breaking change baz
      #   gem 'foo', '< 2.1'
      #
      # @example OnlyFor: ['restrictive_version_specifiers']
      #   # bad
      #
      #   gem 'foo', '< 2.1'
      #
      #   # good
      #
      #   gem 'foo', '>= 1.0'
      #
      #   # Version 2.1 introduces breaking change baz
      #   gem 'foo', '< 2.1'
      #
      # @example OnlyFor: ['version_specifiers', 'github']
      #   # bad
      #
      #   gem 'foo', github: 'some_account/some_fork_of_foo'
      #
      #   gem 'bar', '< 2.1'
      #
      #   # good
      #
      #   # Using this fork because baz
      #   gem 'foo', github: 'some_account/some_fork_of_foo'
      #
      #   # Version 2.1 introduces breaking change baz
      #   gem 'bar', '< 2.1'
      #
      class GemComment < Base
        include DefNode
        include GemDeclaration

        MSG = 'Missing gem description comment.'
        CHECKED_OPTIONS_CONFIG = 'OnlyFor'
        VERSION_SPECIFIERS_OPTION = 'version_specifiers'
        RESTRICTIVE_VERSION_SPECIFIERS_OPTION = 'restrictive_version_specifiers'
        RESTRICTIVE_VERSION_PATTERN = /\A\s*(?:<|~>|\d|=)/.freeze
        RESTRICT_ON_SEND = %i[gem].freeze

        def on_send(node)
          return unless gem_declaration?(node)
          return if ignored_gem?(node)
          return if commented_any_descendant?(node)
          return if cop_config[CHECKED_OPTIONS_CONFIG].any? && !checked_options_present?(node)

          add_offense(node)
        end

        private

        def commented_any_descendant?(node)
          commented?(node) || node.each_descendant.any? { |n| commented?(n) }
        end

        def commented?(node)
          preceding_lines = preceding_lines(node)
          preceding_comment?(node, preceding_lines.last)
        end

        # The args node1 & node2 may represent a RuboCop::AST::Node
        # or a Parser::Source::Comment. Both respond to #loc.
        def precede?(node1, node2)
          node2.loc.line - node1.loc.line <= 1
        end

        def preceding_lines(node)
          processed_source.ast_with_comments[node].select do |line|
            line.loc.line <= node.loc.line
          end
        end

        def preceding_comment?(node1, node2)
          node1 && node2 && precede?(node2, node1) && comment_line?(node2.source)
        end

        def ignored_gem?(node)
          ignored_gems = Array(cop_config['IgnoredGems'])
          ignored_gems.include?(node.first_argument.value)
        end

        def checked_options_present?(node)
          (cop_config[CHECKED_OPTIONS_CONFIG].include?(VERSION_SPECIFIERS_OPTION) &&
            version_specified_gem?(node)) ||
            (cop_config[CHECKED_OPTIONS_CONFIG].include?(RESTRICTIVE_VERSION_SPECIFIERS_OPTION) &&
              restrictive_version_specified_gem?(node)) ||
            contains_checked_options?(node)
        end

        # Besides the gem name, all other *positional* arguments to `gem` are version specifiers,
        # as long as it has one we know there's at least one version specifier.
        def version_specified_gem?(node)
          # arguments[0] is the gem name
          node.arguments[1]&.str_type?
        end

        # Version specifications that restrict all updates going forward. This excludes versions
        # like ">= 1.0" or "!= 2.0.3".
        def restrictive_version_specified_gem?(node)
          return false unless version_specified_gem?(node)

          node.arguments[1..]
              .any? { |arg| arg&.str_type? && RESTRICTIVE_VERSION_PATTERN.match?(arg.value) }
        end

        def contains_checked_options?(node)
          (Array(cop_config[CHECKED_OPTIONS_CONFIG]) & gem_options(node).map(&:to_s)).any?
        end

        def gem_options(node)
          return [] unless node.last_argument&.hash_type?

          node.last_argument.keys.map(&:value)
        end
      end
    end
  end
end
