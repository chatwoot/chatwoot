module SassListen
  class Options
    def initialize(opts, defaults)
      @options = {}
      given_options = opts.dup
      defaults.keys.each do |key|
        @options[key] = given_options.delete(key) || defaults[key]
      end

      return if given_options.empty?

      msg = "Unknown options: #{given_options.inspect}"
      SassListen::Logger.warn msg
      fail msg
    end

    def method_missing(name, *_)
      return @options[name] if @options.key?(name)
      msg = "Bad option: #{name.inspect} (valid:#{@options.keys.inspect})"
      fail NameError, msg
    end
  end
end
