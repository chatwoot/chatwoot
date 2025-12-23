module FactoryBot
  class Linter
    def initialize(factories, strategy: :create, traits: false, verbose: false)
      @factories_to_lint = factories
      @factory_strategy = strategy
      @traits = traits
      @verbose = verbose
      @invalid_factories = calculate_invalid_factories
    end

    def lint!
      if invalid_factories.any?
        raise InvalidFactoryError, error_message
      end
    end

    private

    attr_reader :factories_to_lint, :invalid_factories, :factory_strategy

    def calculate_invalid_factories
      factories_to_lint.each_with_object(Hash.new([])) do |factory, result|
        errors = lint(factory)
        result[factory] |= errors unless errors.empty?
      end
    end

    class FactoryError
      def initialize(wrapped_error, factory)
        @wrapped_error = wrapped_error
        @factory = factory
      end

      def message
        message = @wrapped_error.message
        "* #{location} - #{message} (#{@wrapped_error.class.name})"
      end

      def verbose_message
        <<~MESSAGE
          #{message}
            #{@wrapped_error.backtrace.join("\n  ")}
        MESSAGE
      end

      def location
        @factory.name
      end
    end

    class FactoryTraitError < FactoryError
      def initialize(wrapped_error, factory, trait_name)
        super(wrapped_error, factory)
        @trait_name = trait_name
      end

      def location
        "#{@factory.name}+#{@trait_name}"
      end
    end

    def lint(factory)
      if @traits
        lint_factory(factory) + lint_traits(factory)
      else
        lint_factory(factory)
      end
    end

    def lint_factory(factory)
      result = []
      begin
        FactoryBot.public_send(factory_strategy, factory.name)
      rescue => e
        result |= [FactoryError.new(e, factory)]
      end
      result
    end

    def lint_traits(factory)
      result = []
      factory.definition.defined_traits.map(&:name).each do |trait_name|
        FactoryBot.public_send(factory_strategy, factory.name, trait_name)
      rescue => e
        result |= [FactoryTraitError.new(e, factory, trait_name)]
      end
      result
    end

    def error_message
      lines = invalid_factories.map { |_factory, exceptions|
        exceptions.map(&error_message_type)
      }.flatten

      <<~ERROR_MESSAGE.strip
        The following factories are invalid:

        #{lines.join("\n")}
      ERROR_MESSAGE
    end

    def error_message_type
      if @verbose
        :verbose_message
      else
        :message
      end
    end
  end
end
