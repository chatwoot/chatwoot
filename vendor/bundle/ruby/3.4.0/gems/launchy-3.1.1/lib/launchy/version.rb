# frozen_string_literal: true

module Launchy
  VERSION = "3.1.1"

  # Internal: Version number of Launchy
  module Version
    MAJOR   = Integer(VERSION.split(".")[0])
    MINOR   = Integer(VERSION.split(".")[1])
    PATCH   = Integer(VERSION.split(".")[2])

    def self.to_a
      [MAJOR, MINOR, PATCH]
    end

    def self.to_s
      VERSION
    end
  end
end
