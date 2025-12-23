module FactoryBot
  # @api private
  class Trait
    attr_reader :name, :definition

    def initialize(name, &block)
      @name = name.to_s
      @block = block
      @definition = Definition.new(@name)
      proxy = FactoryBot::DefinitionProxy.new(@definition)

      if block
        proxy.instance_eval(&@block)
      end
    end

    delegate :add_callback, :declare_attribute, :to_create, :define_trait, :constructor,
      :callbacks, :attributes, :klass, :klass=, to: :@definition

    def names
      [@name]
    end

    def ==(other)
      name == other.name &&
        block == other.block
    end

    protected

    attr_reader :block
  end
end
