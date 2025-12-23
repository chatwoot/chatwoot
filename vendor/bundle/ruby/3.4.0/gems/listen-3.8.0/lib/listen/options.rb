# frozen_string_literal: true

module Listen
  class Options
    def initialize(opts, defaults)
      @options = {}
      given_options = opts.dup
      defaults.each_key do |key|
        @options[key] = given_options.delete(key) || defaults[key]
      end

      given_options.empty? or raise ArgumentError, "Unknown options: #{given_options.inspect}"
    end

    # rubocop:disable Lint/MissingSuper
    def respond_to_missing?(name, *_)
      @options.has_key?(name)
    end

    def method_missing(name, *_)
      respond_to_missing?(name) or raise NameError, "Bad option: #{name.inspect} (valid:#{@options.keys.inspect})"
      @options[name]
    end
    # rubocop:enable Lint/MissingSuper
  end
end
