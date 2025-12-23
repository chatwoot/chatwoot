# frozen_string_literal: true

module Nokogiri
  module XSLT
    ###
    # A Stylesheet represents an XSLT Stylesheet object.  Stylesheet creation
    # is done through Nokogiri.XSLT.  Here is an example of transforming
    # an XML::Document with a Stylesheet:
    #
    #   doc   = Nokogiri::XML(File.read('some_file.xml'))
    #   xslt  = Nokogiri::XSLT(File.read('some_transformer.xslt'))
    #
    #   xslt.transform(doc) # => Nokogiri::XML::Document
    #
    # Many XSLT transformations include serialization behavior to emit a non-XML document. For these
    # cases, please take care to invoke the #serialize method on the result of the transformation:
    #
    #   doc   = Nokogiri::XML(File.read('some_file.xml'))
    #   xslt  = Nokogiri::XSLT(File.read('some_transformer.xslt'))
    #   xslt.serialize(xslt.transform(doc)) # => String
    #
    # or use the #apply_to method, which is a shortcut for `serialize(transform(document))`:
    #
    #   doc   = Nokogiri::XML(File.read('some_file.xml'))
    #   xslt  = Nokogiri::XSLT(File.read('some_transformer.xslt'))
    #   xslt.apply_to(doc) # => String
    #
    # See Nokogiri::XSLT::Stylesheet#transform for more information and examples.
    class Stylesheet
      # :call-seq:
      #   apply_to(document, params = []) -> String
      #
      # Apply an XSLT stylesheet to an XML::Document and serialize it properly. This method is
      # equivalent to calling #serialize on the result of #transform.
      #
      # [Parameters]
      # - +document+ is an instance of XML::Document to transform
      # - +params+ is an array of strings used as XSLT parameters, passed into #transform
      #
      # [Returns]
      #   A string containing the serialized result of the transformation.
      #
      # See Nokogiri::XSLT::Stylesheet#transform for more information and examples.
      def apply_to(document, params = [])
        serialize(transform(document, params))
      end
    end
  end
end
