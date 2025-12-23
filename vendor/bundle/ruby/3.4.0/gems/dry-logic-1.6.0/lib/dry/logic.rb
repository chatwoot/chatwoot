# frozen_string_literal: true

require "zeitwerk"
require "dry/core"

module Dry
  module Logic
    include Dry::Core::Constants

    def self.loader
      @loader ||= Zeitwerk::Loader.new.tap do |loader|
        root = File.expand_path("..", __dir__)
        loader.tag = "dry-logic"
        loader.inflector = Zeitwerk::GemInflector.new("#{root}/dry-logic.rb")
        loader.push_dir(root)
        loader.ignore(
          "#{root}/dry-logic.rb",
          "#{root}/dry/logic/version.rb"
        )
      end
    end

    loader.setup
  end
end
