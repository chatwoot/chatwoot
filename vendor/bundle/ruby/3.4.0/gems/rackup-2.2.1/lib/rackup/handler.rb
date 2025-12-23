# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

module Rackup
  # *Handlers* connect web servers with Rack.
  #
  # Rackup includes Handlers for WEBrick and CGI.
  #
  # Handlers usually are activated by calling <tt>MyHandler.run(myapp)</tt>.
  # A second optional hash can be passed to include server-specific
  # configuration.
  module Handler
    @handlers = {}

    # Register a named handler class.
    def self.register(name, klass)
      if klass.is_a?(String)
        warn "Calling Rackup::Handler.register with a string is deprecated, use the class/module itself.", uplevel: 1

        klass = self.const_get(klass, false)
      end

      name = name.to_sym

      @handlers[name] = klass
    end

    def self.[](name)
      name = name.to_sym

      begin
        @handlers[name] || self.const_get(name, false)
      rescue NameError
        # Ignore.
      end
    end

    def self.get(name)
      return nil unless name

      name = name.to_sym

      if server = self[name]
        return server
      end

      begin
        require_handler("rackup/handler", name)
      rescue LoadError
        require_handler("rack/handler", name)
      end

      return self[name]
    end

    RACK_HANDLER = 'RACK_HANDLER'
    RACKUP_HANDLER = 'RACKUP_HANDLER'

    SERVER_NAMES = %i(puma falcon webrick).freeze
    private_constant :SERVER_NAMES

    # Select first available Rack handler given an `Array` of server names.
    # Raises `LoadError` if no handler was found.
    #
    #   > pick ['puma', 'webrick']
    #   => Rackup::Handler::WEBrick
    def self.pick(server_names)
      server_names = Array(server_names)

      server_names.each do |server_name|
        begin
          server = self.get(server_name)
         return server if server
        rescue LoadError
          # Ignore.
        end
      end

      raise LoadError, "Couldn't find handler for: #{server_names.join(', ')}."
    end

    def self.default
      if rack_handler = ENV[RACKUP_HANDLER]
        self.get(rack_handler)
      elsif rack_handler = ENV[RACK_HANDLER]
        warn "RACK_HANDLER is deprecated, use RACKUP_HANDLER."
        self.get(rack_handler)
      else
        pick SERVER_NAMES
      end
    end

    # Transforms server-name constants to their canonical form as filenames,
    # then tries to require them but silences the LoadError if not found
    #
    # Naming convention:
    #
    #   Foo # => 'foo'
    #   FooBar # => 'foo_bar.rb'
    #   FooBAR # => 'foobar.rb'
    #   FOObar # => 'foobar.rb'
    #   FOOBAR # => 'foobar.rb'
    #   FooBarBaz # => 'foo_bar_baz.rb'
    def self.require_handler(prefix, const_name)
      file = const_name.to_s.gsub(/^[A-Z]+/) { |pre| pre.downcase }.
        gsub(/[A-Z]+[^A-Z]/, '_\&').downcase

      require(::File.join(prefix, file))
    end
  end
end
