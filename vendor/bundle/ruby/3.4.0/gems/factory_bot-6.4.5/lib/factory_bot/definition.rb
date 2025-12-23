module FactoryBot
  # @api private
  class Definition
    attr_reader :defined_traits, :declarations, :name, :registered_enums
    attr_accessor :klass

    def initialize(name, base_traits = [])
      @name = name
      @declarations = DeclarationList.new(name)
      @callbacks = []
      @defined_traits = Set.new
      @registered_enums = []
      @to_create = nil
      @base_traits = base_traits
      @additional_traits = []
      @constructor = nil
      @attributes = nil
      @compiled = false
      @expanded_enum_traits = false
    end

    delegate :declare_attribute, to: :declarations

    def attributes
      @attributes ||= AttributeList.new.tap do |attribute_list|
        attribute_lists = aggregate_from_traits_and_self(:attributes) { declarations.attributes }
        attribute_lists.each do |attributes|
          attribute_list.apply_attributes attributes
        end
      end
    end

    def to_create(&block)
      if block
        @to_create = block
      else
        aggregate_from_traits_and_self(:to_create) { @to_create }.last
      end
    end

    def constructor
      aggregate_from_traits_and_self(:constructor) { @constructor }.last
    end

    def callbacks
      aggregate_from_traits_and_self(:callbacks) { @callbacks }
    end

    def compile(klass = nil)
      unless @compiled
        expand_enum_traits(klass) unless klass.nil?

        declarations.attributes

        self.klass ||= klass
        defined_traits.each do |defined_trait|
          defined_trait.klass ||= klass
          base_traits.each { |bt| bt.define_trait defined_trait }
          additional_traits.each { |at| at.define_trait defined_trait }
        end

        @compiled = true

        ActiveSupport::Notifications.instrument "factory_bot.compile_factory", {
          name: name,
          attributes: declarations.attributes,
          traits: defined_traits,
          class: klass || self.klass
        }
      end
    end

    def overridable
      declarations.overridable
      self
    end

    def inherit_traits(new_traits)
      @base_traits += new_traits
    end

    def append_traits(new_traits)
      @additional_traits += new_traits
    end

    def add_callback(callback)
      @callbacks << callback
    end

    def skip_create
      @to_create = ->(instance) {}
    end

    def define_trait(trait)
      @defined_traits.add(trait)
    end

    def register_enum(enum)
      @registered_enums << enum
    end

    def define_constructor(&block)
      @constructor = block
    end

    def before(*names, &block)
      callback(*names.map { |name| "before_#{name}" }, &block)
    end

    def after(*names, &block)
      callback(*names.map { |name| "after_#{name}" }, &block)
    end

    def callback(*names, &block)
      names.each do |name|
        add_callback(Callback.new(name, block))
      end
    end

    private

    def base_traits
      @base_traits.map { |name| trait_by_name(name) }
    rescue KeyError => error
      raise error_with_definition_name(error)
    end

    # detailed_message introduced in Ruby 3.2 for cleaner integration with
    # did_you_mean. See https://bugs.ruby-lang.org/issues/18564
    if KeyError.method_defined?(:detailed_message)
      def error_with_definition_name(error)
        message = error.message + " referenced within \"#{name}\" definition"

        error.class.new(message, key: error.key, receiver: error.receiver)
          .tap { |new_error| new_error.set_backtrace(error.backtrace) }
      end
    else
      def error_with_definition_name(error)
        message = error.message
        message.insert(
          message.index("\nDid you mean?") || message.length,
          " referenced within \"#{name}\" definition"
        )

        error.class.new(message).tap do |new_error|
          new_error.set_backtrace(error.backtrace)
        end
      end
    end

    def additional_traits
      @additional_traits.map { |name| trait_by_name(name) }
    end

    def trait_by_name(name)
      trait_for(name) || Internal.trait_by_name(name, klass)
    end

    def trait_for(name)
      @defined_traits_by_name ||= defined_traits.each_with_object({}) { |t, memo| memo[t.name] ||= t }
      @defined_traits_by_name[name.to_s]
    end

    def initialize_copy(source)
      super
      @attributes = nil
      @compiled = false
      @defined_traits_by_name = nil
    end

    def aggregate_from_traits_and_self(method_name, &block)
      compile

      [
        base_traits.map(&method_name),
        instance_exec(&block),
        additional_traits.map(&method_name)
      ].flatten.compact
    end

    def expand_enum_traits(klass)
      return if @expanded_enum_traits

      if automatically_register_defined_enums?(klass)
        automatically_register_defined_enums(klass)
      end

      registered_enums.each do |enum|
        traits = enum.build_traits(klass)
        traits.each { |trait| define_trait(trait) }
      end

      @expanded_enum_traits = true
    end

    def automatically_register_defined_enums(klass)
      klass.defined_enums.each_key { |name| register_enum(Enum.new(name)) }
    end

    def automatically_register_defined_enums?(klass)
      FactoryBot.automatically_define_enum_traits &&
        klass.respond_to?(:defined_enums)
    end
  end
end
