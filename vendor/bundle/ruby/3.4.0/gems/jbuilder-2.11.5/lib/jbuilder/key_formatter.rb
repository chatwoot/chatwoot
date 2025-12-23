require 'jbuilder/jbuilder'
require 'active_support/core_ext/array'

class Jbuilder
  class KeyFormatter
    def initialize(*args)
      @format = {}
      @cache = {}

      options = args.extract_options!
      args.each do |name|
        @format[name] = []
      end
      options.each do |name, parameters|
        @format[name] = parameters
      end
    end

    def initialize_copy(original)
      @cache = {}
    end

    def format(key)
      @cache[key] ||= @format.inject(key.to_s) do |result, args|
        func, args = args
        if ::Proc === func
          func.call result, *args
        else
          result.send func, *args
        end
      end
    end
  end
end
