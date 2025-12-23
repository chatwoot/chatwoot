# frozen_string_literal: false
require_relative "baseparser"

module REXML
  module Parsers
    class StreamParser
      def initialize source, listener
        @listener = listener
        @parser = BaseParser.new( source )
        @entities = {}
      end

      def add_listener( listener )
        @parser.add_listener( listener )
      end

      def entity_expansion_count
        @parser.entity_expansion_count
      end

      def entity_expansion_limit=( limit )
        @parser.entity_expansion_limit = limit
      end

      def entity_expansion_text_limit=( limit )
        @parser.entity_expansion_text_limit = limit
      end

      def parse
        # entity string
        while true
          event = @parser.pull
          case event[0]
          when :end_document
            return
          when :start_element
            attrs = event[2].each do |n, v|
              event[2][n] = @parser.unnormalize( v )
            end
            @listener.tag_start( event[1], attrs )
          when :end_element
            @listener.tag_end( event[1] )
          when :text
            unnormalized = @parser.unnormalize( event[1], @entities )
            @listener.text( unnormalized )
          when :processing_instruction
            @listener.instruction( *event[1,2] )
          when :start_doctype
            @listener.doctype( *event[1..-1] )
          when :end_doctype
            # FIXME: remove this condition for milestone:3.2
            @listener.doctype_end if @listener.respond_to? :doctype_end
          when :comment, :attlistdecl, :cdata, :xmldecl, :elementdecl
            @listener.send( event[0].to_s, *event[1..-1] )
          when :entitydecl, :notationdecl
            @entities[ event[1] ] = event[2] if event.size == 3
            @listener.send( event[0].to_s, event[1..-1] )
          when :externalentity
            entity_reference = event[1]
            content = entity_reference.gsub(/\A%|;\z/, "")
            @listener.entity(content)
          end
        end
      end
    end
  end
end
