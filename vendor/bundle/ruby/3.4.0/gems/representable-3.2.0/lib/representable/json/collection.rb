require 'representable/json'
require 'representable/hash/collection'

module Representable::JSON
  module Collection
    include Representable::JSON

    def self.included(base)
      base.send :include, Representable::Hash::Collection
    end
  end
end
