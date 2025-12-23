require 'ox' unless defined?(Ox)

# Each MultiXml parser is expected to parse an XML document into a Hash. The
# conversion rules are:
#
# - Each document starts out as an empty Hash.
#
# - Reading an element created an entry in the parent Hash that has a key of
#   the element name and a value of a Hash with attributes as key value
#   pairs. Children are added as described by this rule.
#
# - Text and CDATE is stored in the parent element Hash with a key of
#   MultiXml::CONTENT_ROOT and a value of the text itself.
#
# - If a key already exists in the Hash then the value associated with the key
#   is converted to an Array with the old and new value in it.
#
# - Other elements such as the xml prolog, doctype, and comments are ignored.
#

module MultiXml
  module Parsers
    module Ox #:nodoc:
      extend self

      def parse_error
        Exception
      end

      def parse(io)
        handler = Handler.new
        ::Ox.sax_parse(handler, io, :convert_special => true)
        handler.doc
      end

      class Handler
        attr_accessor :stack

        def initialize
          @stack = []
        end

        def doc
          @stack[0]
        end

        def attr(name, value)
          append(name, value) unless @stack.empty?
        end

        def text(value)
          append(MultiXml::CONTENT_ROOT, value)
        end

        def cdata(value)
          append(MultiXml::CONTENT_ROOT, value)
        end

        def start_element(name)
          @stack.push({}) if @stack.empty?
          h = {}
          append(name, h)
          @stack.push(h)
        end

        def end_element(_)
          @stack.pop
        end

        def error(message, line, column)
          raise(Exception.new("#{message} at #{line}:#{column}"))
        end

        def append(key, value)
          key = key.to_s
          h = @stack.last
          if h.key?(key)
            v = h[key]
            if v.is_a?(Array)
              v << value
            else
              h[key] = [v, value]
            end
          else
            h[key] = value
          end
        end
      end # Handler
    end # Ox
  end # Parsers
end # MultiXml
