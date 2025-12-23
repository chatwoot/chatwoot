gem "multi_json", '>= 1.14.1'
require "multi_json"

require "representable"

module Representable
  # Brings #to_json and #from_json to your object.
  module JSON
    autoload :Collection, "representable/json/collection"

    extend Hash::ClassMethods
    include Hash

    def self.included(base)
      base.class_eval do
        include Representable # either in Hero or HeroRepresentation.
        extend ClassMethods # DISCUSS: do that only for classes?
        register_feature Representable::JSON
      end
    end


    module ClassMethods
      def format_engine
        Representable::Hash
      end

      def collection_representer_class
        JSON::Collection
      end
    end


    # Parses the body as JSON and delegates to #from_hash.
    def from_json(data, *args)
      data = MultiJson.load(data)
      from_hash(data, *args)
    end

    # Returns a JSON string representing this object.
    def to_json(*args)
      MultiJson.dump to_hash(*args)
    end

    alias_method :render, :to_json
    alias_method :parse, :from_json
  end
end
