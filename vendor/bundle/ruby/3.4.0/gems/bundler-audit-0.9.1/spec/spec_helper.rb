require 'simplecov'
SimpleCov.start

require 'rspec'
require 'bundler/audit/database'

module Fixtures
  ROOT = File.expand_path('../fixtures',__FILE__)

  TMP_DIR = File.expand_path('../tmp',__FILE__)

  module Database
    PATH = File.join(ROOT,'database')

    COMMIT = '89cdde9a725bb6f8a483bca97c5da344e060ac61'

    def self.clone
      system 'git', 'clone', '--quiet', Bundler::Audit::Database::URL, PATH
    end

    def self.reset!(commit=COMMIT)
      Dir.chdir(PATH) do
        system 'git', 'reset', '--hard', commit
      end
    end
  end

  def self.join(*paths)
    File.join(ROOT,*paths)
  end
end

module Helpers
  def sh(command, options={})
    result = `#{command} 2>&1`

    if $?.success? == !!options[:fail]
      raise "FAILED #{command}\n#{result}"
    end

    result
  end

  def decolorize(string)
    string.gsub(/\e\[\d+m/, "")
  end
end

include Bundler::Audit

RSpec.configure do |config|
  include Helpers

  config.before(:suite) do
    unless File.directory?(Fixtures::Database::PATH)
      Fixtures::Database.clone
    end

    Fixtures::Database.reset!

    FileUtils.mkdir_p(Fixtures::TMP_DIR)
  end

  config.before(:each) do
    stub_const("Bundler::Audit::Database::DEFAULT_PATH",Fixtures::Database::PATH)
  end
end
