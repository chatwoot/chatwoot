module FactoryBot
  class Declaration
    # @api private
    class Implicit < Declaration
      def initialize(name, factory = nil, ignored = false)
        super(name, ignored)
        @factory = factory
      end

      def ==(other)
        self.class == other.class &&
          name == other.name &&
          factory == other.factory &&
          ignored == other.ignored
      end

      protected

      attr_reader :factory

      private

      def build
        if FactoryBot.factories.registered?(name)
          [Attribute::Association.new(name, name, {})]
        elsif FactoryBot::Internal.sequences.registered?(name)
          [Attribute::Sequence.new(name, name, @ignored)]
        elsif @factory.name.to_s == name.to_s
          message = "Self-referencing trait '#{@name}'"
          raise TraitDefinitionError, message
        else
          @factory.inherit_traits([name])
          []
        end
      end
    end
  end
end
