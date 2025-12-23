module FactoryBot
  # @api private
  class NullObject < ::BasicObject
    def initialize(methods_to_respond_to)
      @methods_to_respond_to = methods_to_respond_to.map(&:to_s)
    end

    def method_missing(name, *args, &block) # rubocop:disable Style/MissingRespondToMissing
      if respond_to?(name)
        nil
      else
        super
      end
    end

    def respond_to?(method)
      @methods_to_respond_to.include? method.to_s
    end
  end
end
