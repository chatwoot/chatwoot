# frozen_string_literal: true
require 'sprockets/autoload'
require 'sprockets/digest_utils'

module Sprockets
  class JSMincCompressor
    VERSION = '1'

    def self.instance
      @instance ||= new
    end

    def self.call(input)
      instance.call(input)
    end

    def self.cache_key
      instance.cache_key
    end

    attr_reader :cache_key

    def initialize(options = {})
      @compressor_class = Autoload::JSMinC
      @cache_key = "#{self.class.name}:#{Autoload::JSMinC::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}".freeze
    end

    def call(input)
      @compressor_class.minify(input[:data])
    end
  end
end
