require "active_support/core_ext/hash/indifferent_access"

module FactoryBot
  class Registry
    include Enumerable

    attr_reader :name

    def initialize(name)
      @name = name
      @items = ActiveSupport::HashWithIndifferentAccess.new
    end

    def clear
      @items.clear
    end

    def each(&block)
      @items.values.uniq.each(&block)
    end

    def find(name)
      @items.fetch(name)
    rescue KeyError => e
      raise key_error_with_custom_message(e)
    end

    alias_method :[], :find

    def register(name, item)
      @items[name] = item
    end

    def registered?(name)
      @items.key?(name)
    end

    private

    def key_error_with_custom_message(key_error)
      message = key_error.message.sub("key not found", "#{@name} not registered")
      new_key_error(message, key_error).tap do |error|
        error.set_backtrace(key_error.backtrace)
      end
    end

    # detailed_message introduced in Ruby 3.2 for cleaner integration with
    # did_you_mean. See https://bugs.ruby-lang.org/issues/18564
    if KeyError.method_defined?(:detailed_message)
      def new_key_error(message, key_error)
        KeyError.new(message, key: key_error.key, receiver: key_error.receiver)
      end
    else
      def new_key_error(message, _)
        KeyError.new(message)
      end
    end
  end
end
