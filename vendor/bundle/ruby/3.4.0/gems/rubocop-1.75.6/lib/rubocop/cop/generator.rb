# frozen_string_literal: true

module RuboCop
  module Cop
    # Source and spec generator for new cops
    #
    # This generator will take a cop name and generate a source file
    # and spec file when given a valid qualified cop name.
    # @api private
    class Generator
      SOURCE_TEMPLATE = <<~RUBY
        # frozen_string_literal: true

        module RuboCop
          module Cop
            module %<department>s
              # TODO: Write cop description and example of bad / good code. For every
              # `SupportedStyle` and unique configuration, there needs to be examples.
              # Examples must have valid Ruby syntax. Do not use upticks.
              #
              # @safety
              #   Delete this section if the cop is not unsafe (`Safe: false` or
              #   `SafeAutoCorrect: false`), or use it to explain how the cop is
              #   unsafe.
              #
              # @example EnforcedStyle: bar (default)
              #   # Description of the `bar` style.
              #
              #   # bad
              #   bad_bar_method
              #
              #   # bad
              #   bad_bar_method(args)
              #
              #   # good
              #   good_bar_method
              #
              #   # good
              #   good_bar_method(args)
              #
              # @example EnforcedStyle: foo
              #   # Description of the `foo` style.
              #
              #   # bad
              #   bad_foo_method
              #
              #   # bad
              #   bad_foo_method(args)
              #
              #   # good
              #   good_foo_method
              #
              #   # good
              #   good_foo_method(args)
              #
              class %<cop_name>s < Base
                # TODO: Implement the cop in here.
                #
                # In many cases, you can use a node matcher for matching node pattern.
                # See https://github.com/rubocop/rubocop-ast/blob/master/lib/rubocop/ast/node_pattern.rb
                #
                # For example
                MSG = 'Use `#good_method` instead of `#bad_method`.'

                # TODO: Don't call `on_send` unless the method name is in this list
                # If you don't need `on_send` in the cop you created, remove it.
                RESTRICT_ON_SEND = %%i[bad_method].freeze

                # @!method bad_method?(node)
                def_node_matcher :bad_method?, <<~PATTERN
                  (send nil? :bad_method ...)
                PATTERN

                # Called on every `send` node (method call) while walking the AST.
                # TODO: remove this method if inspecting `send` nodes is unneeded for your cop.
                # By default, this is aliased to `on_csend` as well to handle method calls
                # with safe navigation, remove the alias if this is unnecessary.
                # If kept, ensure your tests cover safe navigation as well!
                def on_send(node)
                  return unless bad_method?(node)

                  add_offense(node)
                end
                alias on_csend on_send
              end
            end
          end
        end
      RUBY

      SPEC_TEMPLATE = <<~SPEC
        # frozen_string_literal: true

        RSpec.describe RuboCop::Cop::%<department>s::%<cop_name>s, :config do
          let(:config) { RuboCop::Config.new }

          # TODO: Write test code
          #
          # For example
          it 'registers an offense when using `#bad_method`' do
            expect_offense(<<~RUBY)
              bad_method
              ^^^^^^^^^^ Use `#good_method` instead of `#bad_method`.
            RUBY
          end

          it 'does not register an offense when using `#good_method`' do
            expect_no_offenses(<<~RUBY)
              good_method
            RUBY
          end
        end
      SPEC

      CONFIGURATION_ADDED_MESSAGE =
        '[modify] A configuration for the cop is added into ' \
        '%<configuration_file_path>s.'

      def initialize(name, output: $stdout)
        @badge = Badge.parse(name)
        @output = output
        return if badge.qualified?

        raise ArgumentError, 'Specify a cop name with Department/Name style'
      end

      def write_source
        write_unless_file_exists(source_path, generated_source)
      end

      def write_spec
        write_unless_file_exists(spec_path, generated_spec)
      end

      def inject_require(root_file_path: 'lib/rubocop.rb')
        RequireFileInjector.new(source_path: source_path, root_file_path: root_file_path).inject
      end

      def inject_config(config_file_path: 'config/default.yml',
                        version_added: '<<next>>')
        injector =
          ConfigurationInjector.new(configuration_file_path: config_file_path,
                                    badge: badge,
                                    version_added: version_added)

        injector.inject do # rubocop:disable Lint/UnexpectedBlockArity
          output.puts(format(CONFIGURATION_ADDED_MESSAGE,
                             configuration_file_path: config_file_path))
        end
      end

      def todo
        <<~TODO
          Do 4 steps:
            1. Modify the description of #{badge} in config/default.yml
            2. Implement your new cop in the generated file!
            3. Commit your new cop with a message such as
               e.g. "Add new `#{badge}` cop"
            4. Run `bundle exec rake changelog:new` to generate a changelog entry
               for your new cop.
        TODO
      end

      private

      attr_reader :badge, :output

      def write_unless_file_exists(path, contents)
        if File.exist?(path)
          warn "rake new_cop: #{path} already exists!"
          exit!
        end

        dir = File.dirname(path)
        FileUtils.mkdir_p(dir)

        File.write(path, contents)
        output.puts "[create] #{path}"
      end

      def generated_source
        generate(SOURCE_TEMPLATE)
      end

      def generated_spec
        generate(SPEC_TEMPLATE)
      end

      def generate(template)
        format(template, department: badge.department.to_s.gsub('/', '::'),
                         cop_name: badge.cop_name)
      end

      def spec_path
        File.join(
          'spec',
          'rubocop',
          'cop',
          snake_case(badge.department.to_s),
          "#{snake_case(badge.cop_name.to_s)}_spec.rb"
        )
      end

      def source_path
        File.join(
          'lib',
          'rubocop',
          'cop',
          snake_case(badge.department.to_s),
          "#{snake_case(badge.cop_name.to_s)}.rb"
        )
      end

      def snake_case(camel_case_string)
        camel_case_string
          .gsub('RSpec', 'Rspec')
          .gsub(%r{([^A-Z/])([A-Z]+)}, '\1_\2')
          .gsub(%r{([A-Z])([A-Z][^A-Z\d/]+)}, '\1_\2')
          .downcase
      end
    end
  end
end
