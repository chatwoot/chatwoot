# frozen_string_literal: true

require "test_prof"
require "test_prof/recipes/rspec/before_all"

module TestProf
  # Just like `let`, but persist the result for the whole group.
  # NOTE: Experimental and magical, for more control use `before_all`.
  module LetItBe
    Modifier = Struct.new(:scope, :block) do
      def call(record, config)
        block.call(record, config)
      end
    end

    class Configuration
      # Define an alias for `let_it_be` with the predefined options:
      #
      #   TestProf::LetItBe.configure do |config|
      #     config.alias_to :let_it_be_reloaded, reload: true
      #   end
      def alias_to(name, **default_args)
        LetItBe.define_let_it_be_alias(name, **default_args)
      end

      # Register modifier by providing the name of key,
      # optional scope (when to apply the modifier, on initialization (:initialize)
      # or when accessed # via let (:let))
      def register_modifier(key, on: :let, &block)
        raise ArgumentError, "Modifier #{key} is already defined for let_it_be" if LetItBe.modifiers.key?(key)

        LetItBe.modifiers[key] = Modifier.new(on, block)
      end

      def default_modifiers
        @default_modifiers ||= {}
      end
    end

    class << self
      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      def modifiers
        @modifiers ||= {}
      end

      def wrap_with_modifiers(mods, on: :let, &block)
        mods = mods.select { |k, val| LetItBe.modifiers.fetch(k).scope == on }
        return block if mods.empty?

        validate_modifiers! mods

        proc do
          record = instance_eval(&block)
          mods.inject(record) do |rec, (k, v)|
            LetItBe.modifiers.fetch(k).call(rec, v)
          end
        end
      end

      def module_for(group)
        modules[group] ||= Module.new.tap { |mod| group.prepend(mod) }
      end

      private

      def modules
        @modules ||= {}
      end

      def validate_modifiers!(mods)
        unknown = mods.keys - modifiers.keys
        return if unknown.empty?

        raise ArgumentError, "Unknown let_it_be modifiers were used: #{unknown.join(", ")}. " \
                             "Available modifiers are: #{modifiers.keys.join(", ")}"
      end
    end

    # Use uniq prefix for instance variables to avoid collisions
    # We want to use the power of Ruby's unicode support)
    # And we love cats!)
    # Allow overriding the prefix (there are some intermittent issues on JRuby still)
    PREFIX = ENV.fetch("LET_IT_BE_IVAR_PREFIX", "@😸")

    FROZEN_ERROR_HINT = "\nIf you are using `let_it_be`, you may want to pass `reload: true` or `refind: true` modifier to it."

    def self.define_let_it_be_alias(name, **default_args)
      define_method(name) do |identifier, **options, &blk|
        let_it_be(identifier, **default_args.merge(options), &blk)
      end
    end

    def let_it_be(identifier, **options, &block)
      initializer = proc do
        instance_variable_set(:"#{TestProf::LetItBe::PREFIX}#{identifier}", instance_exec(&block))
      rescue FrozenError => e
        raise e.exception("#{e.message}#{TestProf::LetItBe::FROZEN_ERROR_HINT}")
      end

      default_options = LetItBe.config.default_modifiers.dup
      default_options.merge!(metadata[:let_it_be_modifiers]) if metadata[:let_it_be_modifiers]

      options = default_options.merge(options)

      initializer = LetItBe.wrap_with_modifiers(options, on: :initialize, &initializer)

      before_all(&initializer)

      let_accessor = LetItBe.wrap_with_modifiers(options, on: :let) do
        instance_variable_get(:"#{PREFIX}#{identifier}")
      end

      LetItBe.module_for(self).module_eval do
        define_method(identifier) do
          # Trying to detect the context
          # First, check for ::RSpec.current_scope (modern RSpec) and then read @__inspect_output
          # (based on https://github.com/rspec/rspec-rails/commit/7cb796db064f58da7790a92e73ab906ef50b1f34)
          if ::RSpec.respond_to?(:current_scope) && %i[before_all before_context_hook after_context_hook].include?(::RSpec.current_scope)
            instance_variable_get(:"#{PREFIX}#{identifier}")
          elsif /(before|after)\(:context\)/.match?(@__inspect_output) || @__inspect_output.include?("before_all")
            instance_variable_get(:"#{PREFIX}#{identifier}")
          else
            super()
          end
        end
      end

      let(identifier, &let_accessor)
    end

    module Freezer
      # Stoplist to prevent freezing objects and theirs associations that are defined
      # with `let_it_be`'s `freeze: false` options during deep freezing.
      #
      # To only keep track of objects that are available in current example group,
      # `begin` adds a new layer, and `rollback` removes a layer of unrelated objects
      # along with rolling back the transaction where they were created.
      #
      # Stoplist holds records declared with `freeze: false` (so we do not freeze them even if they're used as
      # associated records for frozen objects)
      module Stoplist
        class << self
          def stop?(record)
            @stoplist.any? { |layer| layer.include?(record) }
          end

          def stop!(record)
            @stoplist.last.push(record)
          end

          def begin
            @stoplist.push([])
          end

          def rollback
            @stoplist.pop
          end
        end

        # Stack of example group-related variable definitions
        @stoplist = []
      end

      class << self
        # Rerucsively freezes the object to detect modifications
        def deep_freeze(record)
          return if record.frozen?
          return if Stoplist.stop?(record)

          record.freeze

          # Support `let_it_be` with `create_list`
          return record.each { |rec| deep_freeze(rec) } if record.respond_to?(:each)

          # Freeze associations as well.
          return unless defined?(::ActiveRecord::Base)
          return unless record.is_a?(::ActiveRecord::Base)

          record.class.reflections.keys.each do |reflection|
            # But only if they are already loaded. If not yet loaded, they weren't
            # created by factories, and it's ok to mutate them.

            next unless record.association(reflection.to_sym).loaded?

            target = record.association(reflection.to_sym).target
            deep_freeze(target) if target.is_a?(::ActiveRecord::Base) || target.respond_to?(:each)
          end
        end
      end
    end
  end
end

if defined?(::ActiveRecord::Base)
  require "test_prof/ext/active_record_refind"
  using TestProf::Ext::ActiveRecordRefind

  TestProf::LetItBe.configure do |config|
    config.register_modifier :reload do |record, val|
      next record unless val

      next record.reload if record.is_a?(::ActiveRecord::Base)

      if record.respond_to?(:to_ary)
        next record.map do |rec|
          rec.is_a?(::ActiveRecord::Base) ? rec.reload : rec
        end
      end
      record
    end

    config.register_modifier :refind do |record, val|
      next record unless val

      next record.refind if record.is_a?(::ActiveRecord::Base)

      if record.respond_to?(:to_ary)
        next record.map do |rec|
          rec.is_a?(::ActiveRecord::Base) ? rec.refind : rec
        end
      end
      record
    end

    config.register_modifier :freeze, on: :initialize do |record, val|
      if val == false
        TestProf::LetItBe::Freezer::Stoplist.stop!(record)
        next record
      end

      TestProf::LetItBe::Freezer.deep_freeze(record)
      record
    end
  end
end

RSpec::Core::ExampleGroup.extend TestProf::LetItBe

TestProf::BeforeAll.configure do |config|
  config.before(:begin) do
    TestProf::LetItBe::Freezer::Stoplist.begin
  end

  config.after(:rollback) do
    TestProf::LetItBe::Freezer::Stoplist.rollback
  end
end

RSpec.configure do |config|
  config.after(:example) do |example|
    if example.exception&.is_a?(FrozenError)
      example.exception.message << TestProf::LetItBe::FROZEN_ERROR_HINT unless example.exception.message.frozen?
    end
  end
end
