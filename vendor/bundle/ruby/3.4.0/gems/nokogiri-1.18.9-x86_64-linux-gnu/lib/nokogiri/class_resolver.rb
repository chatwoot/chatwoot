# coding: utf-8
# frozen_string_literal: true

require "set"

module Nokogiri
  #
  # Some classes in Nokogiri are namespaced as a group, for example
  # Document, DocumentFragment, and Builder.
  #
  # It's sometimes necessary to look up the related class, e.g.:
  #
  #   XML::Builder → XML::Document
  #   HTML4::Builder → HTML4::Document
  #   HTML5::Document → HTML5::DocumentFragment
  #
  # This module is included into those key classes who need to do this.
  #
  module ClassResolver
    # #related_class restricts matching namespaces to those matching this set.
    VALID_NAMESPACES = Set.new(["HTML", "HTML4", "HTML5", "XML", "SAX"])

    # :call-seq:
    #   related_class(class_name) → Class
    #
    # Find a class constant within the
    #
    # Some examples:
    #
    #   Nokogiri::XML::Document.new.related_class("DocumentFragment")
    #   # => Nokogiri::XML::DocumentFragment
    #   Nokogiri::HTML4::Document.new.related_class("DocumentFragment")
    #   # => Nokogiri::HTML4::DocumentFragment
    #
    # Note this will also work for subclasses that follow the same convention, e.g.:
    #
    #   Loofah::HTML::Document.new.related_class("DocumentFragment")
    #   # => Loofah::HTML::DocumentFragment
    #
    # And even if it's a subclass, this will iterate through the superclasses:
    #
    #   class ThisIsATopLevelClass < Nokogiri::HTML4::Builder ; end
    #   ThisIsATopLevelClass.new.related_class("Document")
    #   # => Nokogiri::HTML4::Document
    #
    def related_class(class_name)
      klass = nil
      inspecting = self.class

      while inspecting
        namespace_path = inspecting.name.split("::")[0..-2]
        inspecting = inspecting.superclass

        next unless VALID_NAMESPACES.include?(namespace_path.last)

        related_class_name = (namespace_path << class_name).join("::")
        klass = begin
          Object.const_get(related_class_name)
        rescue NameError
          nil
        end
        break if klass
      end
      klass
    end
  end
end
