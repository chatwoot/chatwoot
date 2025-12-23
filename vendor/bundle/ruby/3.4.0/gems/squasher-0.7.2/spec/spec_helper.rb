module SpecHelpers
  def fake_root
    File.join(File.dirname(__FILE__), 'fake_app')
  end
end

module Squasher
  class Dir < ::Dir
    def self.pwd
      File.join(File.dirname(__FILE__), 'fake_app')
    end
  end

  def puts(*)
  end
end

require 'bundler/setup'
Bundler.require

RSpec.configure do |config|
  config.order = 'random'
  config.include SpecHelpers

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
