# frozen_string_literal: true
require 'sprockets/compressing'
require 'sprockets/dependencies'
require 'sprockets/mime'
require 'sprockets/paths'
require 'sprockets/processing'
require 'sprockets/exporting'
require 'sprockets/transformers'
require 'sprockets/utils'

module Sprockets
  module Configuration
    include Paths, Mime, Transformers, Processing, Exporting, Compressing, Dependencies, Utils

    def initialize_configuration(parent)
      @config = parent.config
      @logger = parent.logger
      @context_class = Class.new(parent.context_class)
    end

    attr_reader :config

    def config=(config)
      raise TypeError, "can't assign mutable config" unless config.frozen?
      @config = config
    end

    # Get and set `Logger` instance.
    attr_accessor :logger

    # The `Environment#version` is a custom value used for manually
    # expiring all asset caches.
    #
    # Sprockets is able to track most file and directory changes and
    # will take care of expiring the cache for you. However, its
    # impossible to know when any custom helpers change that you mix
    # into the `Context`.
    #
    # It would be wise to increment this value anytime you make a
    # configuration change to the `Environment` object.
    def version
      config[:version]
    end

    # Assign an environment version.
    #
    #     environment.version = '2.0'
    #
    def version=(version)
      self.config = hash_reassoc(config, :version) { version.dup }
    end

    # Public: Returns a `Digest` implementation class.
    #
    # Defaults to `Digest::SHA256`.
    def digest_class
      config[:digest_class]
    end

    # Deprecated: Assign a `Digest` implementation class. This maybe any Ruby
    # `Digest::` implementation such as `Digest::SHA256` or
    # `Digest::SHA512`.
    #
    #     environment.digest_class = Digest::SHA512
    #
    def digest_class=(klass)
      self.config = config.merge(digest_class: klass).freeze
    end

    # This class maybe mutated and mixed in with custom helpers.
    #
    #     environment.context_class.instance_eval do
    #       include MyHelpers
    #       def asset_url; end
    #     end
    #
    attr_reader :context_class
  end
end
