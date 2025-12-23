# frozen_string_literal: true

require 'sprockets/sass_compressor'
require 'securerandom'

class Sprockets::SassCompressor
  def initialize(options = {})
    @options = {
      syntax: :scss,
      cache: false,
      read_cache: false,
      style: :compressed
    }.merge(options).freeze
    @cache_key = SecureRandom.uuid
  end

  def call(*args)
    input = if defined?(data)
      data # sprockets 2.x
    else
      args[0][:data] #sprockets 3.x
    end

    SassC::Engine.new(
      input,
      {
        style: :compressed
      }
    ).render
  end

  # sprockets 2.x
  alias :evaluate :call
end
