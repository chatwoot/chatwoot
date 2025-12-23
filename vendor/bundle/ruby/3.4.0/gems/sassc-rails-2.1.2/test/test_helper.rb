# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "pry"
require "fileutils"
require 'rails'
require 'bundler/setup'
require "minitest/autorun"
require 'mocha/minitest'

Bundler.require

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
