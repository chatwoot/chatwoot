# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/ecma-re-validator'

RSpec.configure do |config|
  # Use color in STDOUT
  config.color = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  # Run in a random order
  config.order = :random
end
