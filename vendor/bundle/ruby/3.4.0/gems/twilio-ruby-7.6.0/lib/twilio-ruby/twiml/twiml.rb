require 'nokogiri'

module Twilio
  module TwiML
    autoload :FaxResponse, File.join(File.dirname(__FILE__), "fax_response.rb")
    autoload :MessagingResponse, File.join(File.dirname(__FILE__), "messaging_response.rb")
    autoload :VoiceResponse, File.join(File.dirname(__FILE__), "voice_response.rb")
    
    class TwiMLError < StandardError; end

    class LeafNode
      def initialize(content)
        @content = content
      end
    end

    class Comment < LeafNode
      def xml(document)
        Nokogiri::XML::Comment.new(document, @content)
      end
    end

    class Text < LeafNode
      def xml(document)
        Nokogiri::XML::Text.new(@content, document)
      end
    end

    class TwiML
        attr_accessor :name

        def initialize(**keyword_args)
          @overrides = {
              aliasAttribute: 'alias',
              xmlLang: 'xml:lang',
              interpretAs: 'interpret-as',
              for_: 'for',
          }
          @name = self.class.name.split('::').last
          @value = nil
          @verbs = []
          @attrs = {}

          keyword_args.each do |key, val|
            corrected_key = @overrides.fetch(key, TwiML.to_lower_camel_case(key))
            @attrs[corrected_key] = val unless val.nil?
          end
        end

        def self.to_lower_camel_case(symbol)
          # Symbols don't have the .split method, so convert to string first
          result = symbol.to_s
          if result.include? '_'
            result = result.split('_').map(&:capitalize).join
          end
          result[0].downcase + result[1..result.length]
        end

        def to_s(xml_declaration = true)
          save_opts = Nokogiri::XML::Node::SaveOptions::DEFAULT_XML
          if !xml_declaration
            save_opts = save_opts | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
          end
          opts = { encoding: 'UTF-8', indent: 0, save_with: save_opts }
          document = Nokogiri::XML::Document.new
          document << self.xml(document)
          document.to_xml(opts)
        end

        def xml(document)
          # create XML element
          value = (@value.is_a?(String) or @value == nil) ? @value : JSON.generate(@value)
          elem = Nokogiri::XML::Node.new(@name, document)
          elem.content = value
          # set element attributes
          keys = @attrs.keys.sort
          keys.each do |key|
            value = @attrs[key]

            value_is_boolean = value.is_a?(TrueClass) || value.is_a?(FalseClass)
            elem[key] = value_is_boolean ? value.to_s.downcase : value.to_s
          end

          @verbs.each do |verb|
            elem << verb.xml(document)
          end

          elem
        end

        def append(verb)
          unless verb.is_a?(TwiML) || verb.is_a?(LeafNode)
              raise TwiMLError, 'Only appending of TwiML is allowed'
          end

          @verbs << verb
          self
        end

        def comment(body)
          append(Comment.new(body))
        end

        def add_text(content)
          append(Text.new(content))
        end

        def add_child(name, value=nil, **keyword_args)
          node = GenericNode.new(name, value, **keyword_args)

          yield node if block_given?
          append(node)
        end

      alias to_xml to_s
    end

    class GenericNode < TwiML
      def initialize(name, value, **keyword_args)
        super(**keyword_args)
        @name = name
        @value = value
      end
    end
  end
end