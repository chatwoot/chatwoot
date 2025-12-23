module GLI
  class Argument #:nodoc:

    attr_reader :name
    attr_reader :options

    def initialize(name,options = [])
      @name = name
      @options = options
    end

    def optional?
      @options.include? :optional
    end

    def multiple?
      @options.include? :multiple
    end
  end
end
