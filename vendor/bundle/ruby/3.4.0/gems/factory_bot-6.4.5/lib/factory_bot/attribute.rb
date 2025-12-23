require "factory_bot/attribute/dynamic"
require "factory_bot/attribute/association"
require "factory_bot/attribute/sequence"

module FactoryBot
  # @api private
  class Attribute
    attr_reader :name, :ignored

    def initialize(name, ignored)
      @name = name.to_sym
      @ignored = ignored
    end

    def to_proc
      -> {}
    end

    def association?
      false
    end

    def alias_for?(attr)
      FactoryBot.aliases_for(attr).include?(name)
    end
  end
end
