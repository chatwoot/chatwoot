# frozen_string_literal: true

module Nokogiri
  module XML
    class Node
      ###
      # Save options for serializing nodes.
      # See the method group entitled Node@Serialization+and+Generating+Output for usage.
      class SaveOptions
        # Format serialized xml
        FORMAT          = 1
        # Do not include declarations
        NO_DECLARATION  = 2
        # Do not include empty tags
        NO_EMPTY_TAGS   = 4
        # Do not save XHTML
        NO_XHTML        = 8
        # Save as XHTML
        AS_XHTML        = 16
        # Save as XML
        AS_XML          = 32
        # Save as HTML
        AS_HTML         = 64

        if Nokogiri.jruby?
          # Save builder created document
          AS_BUILDER = 128
          # the default for XML documents
          DEFAULT_XML  = AS_XML # https://github.com/sparklemotion/nokogiri/issues/#issue/415
          # the default for HTML document
          DEFAULT_HTML = NO_DECLARATION | NO_EMPTY_TAGS | AS_HTML
          # the default for XHTML document
          DEFAULT_XHTML = NO_DECLARATION | AS_XHTML
        else
          # the default for XML documents
          DEFAULT_XML  = FORMAT | AS_XML
          # the default for HTML document
          DEFAULT_HTML = FORMAT | NO_DECLARATION | NO_EMPTY_TAGS | AS_HTML
          # the default for XHTML document
          DEFAULT_XHTML = FORMAT | NO_DECLARATION | AS_XHTML
        end

        # Integer representation of the SaveOptions
        attr_reader :options

        # Create a new SaveOptions object with +options+
        def initialize(options = 0)
          @options = options
        end

        constants.each do |constant|
          class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{constant.downcase}
              @options |= #{constant}
              self
            end

            def #{constant.downcase}?
              #{constant} & @options == #{constant}
            end
          RUBY
        end

        alias_method :to_i, :options

        def inspect
          options = []
          self.class.constants.each do |k|
            options << k.downcase if send(:"#{k.downcase}?")
          end
          super.sub(/>$/, " " + options.join(", ") + ">")
        end
      end
    end
  end
end
