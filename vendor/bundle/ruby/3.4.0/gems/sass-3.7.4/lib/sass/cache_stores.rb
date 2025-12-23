require 'stringio'

module Sass
  # Sass cache stores are in charge of storing cached information,
  # especially parse trees for Sass documents.
  #
  # User-created importers must inherit from {CacheStores::Base}.
  module CacheStores
  end
end

require 'sass/cache_stores/base'
require 'sass/cache_stores/filesystem'
require 'sass/cache_stores/memory'
require 'sass/cache_stores/chain'
