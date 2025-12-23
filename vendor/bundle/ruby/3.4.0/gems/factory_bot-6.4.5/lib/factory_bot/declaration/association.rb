module FactoryBot
  class Declaration
    # @api private
    class Association < Declaration
      def initialize(name, *options)
        super(name, false)
        @options = options.dup
        @overrides = options.extract_options!
        @factory_name = @overrides.delete(:factory) || name
        @traits = options
      end

      def ==(other)
        self.class == other.class &&
          name == other.name &&
          options == other.options
      end

      protected

      attr_reader :options

      private

      attr_reader :factory_name, :overrides, :traits

      def build
        raise_if_arguments_are_declarations!

        [
          Attribute::Association.new(
            name,
            factory_name,
            [traits, overrides].flatten
          )
        ]
      end

      def raise_if_arguments_are_declarations!
        if factory_name.is_a?(Declaration)
          raise ArgumentError.new(<<~MSG)
            Association '#{name}' received an invalid factory argument.
            Did you mean? 'factory: :#{factory_name.name}'
          MSG
        end

        overrides.each do |attribute, value|
          if value.is_a?(Declaration)
            raise ArgumentError.new(<<~MSG)
              Association '#{name}' received an invalid attribute override.
              Did you mean? '#{attribute}: :#{value.name}'
            MSG
          end
        end
      end
    end
  end
end
