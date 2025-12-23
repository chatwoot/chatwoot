# frozen_string_literal: true

# third party gems
require "hashie"
require "version_gem"

require_relative "snaky_hash/version"
require_relative "snaky_hash/snake"
require_relative "snaky_hash/string_keyed"
require_relative "snaky_hash/symbol_keyed"

# This is the namespace for this gem
module SnakyHash
end

SnakyHash::Version.class_eval do
  extend VersionGem::Basic
end
