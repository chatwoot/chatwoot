require 'psych'
require 'representable'

module Representable
  module YAML
    autoload :Binding, 'representable/yaml/binding'
    include Hash

    def self.included(base)
      base.class_eval do
        include Representable
        register_feature Representable::YAML
        extend ClassMethods
      end
    end

    module ClassMethods
      def format_engine
        Representable::YAML
      end
    end

    def from_yaml(doc, options={})
      hash = Psych.load(doc)
      from_hash(hash, options, Binding)
    end

    # Returns a Nokogiri::XML object representing this object.
    def to_ast(options={})
      Psych::Nodes::Mapping.new.tap do |map|
        create_representation_with(map, options, Binding)
      end
    end

    def to_yaml(*args)
      stream = Psych::Nodes::Stream.new
      stream.children << doc = Psych::Nodes::Document.new

      doc.children << to_ast(*args)
      stream.to_yaml
    end

    alias_method :render, :to_yaml
    alias_method :parse, :from_yaml
  end
end
