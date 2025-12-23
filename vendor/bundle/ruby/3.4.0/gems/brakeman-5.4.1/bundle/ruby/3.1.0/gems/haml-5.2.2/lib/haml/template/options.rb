# frozen_string_literal: true

# We keep options in its own self-contained file
# so that we can load it independently in Rails 3,
# where the full template stuff is lazy-loaded.

module Haml
  module Template
    extend self

    class Options < Hash
      def []=(key, value)
        super
        if Haml::Options.buffer_defaults.key?(key)
          Haml::Options.buffer_defaults[key] = value
        end
      end
    end

    @options = ::Haml::Template::Options.new
    # The options hash for Haml when used within Rails.
    # See {file:REFERENCE.md#options the Haml options documentation}.
    #
    # @return [Haml::Template::Options<Symbol => Object>]
    attr_accessor :options
  end
end
