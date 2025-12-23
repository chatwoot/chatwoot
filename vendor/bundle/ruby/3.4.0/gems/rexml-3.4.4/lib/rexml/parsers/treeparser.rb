# frozen_string_literal: false
require_relative '../validation/validationexception'
require_relative '../undefinednamespaceexception'

module REXML
  module Parsers
    class TreeParser
      def initialize( source, build_context = Document.new )
        @build_context = build_context
        @parser = Parsers::BaseParser.new( source )
      end

      def add_listener( listener )
        @parser.add_listener( listener )
      end

      def parse
        entities = nil
        begin
          while true
            event = @parser.pull
            #STDERR.puts "TREEPARSER GOT #{event.inspect}"
            case event[0]
            when :end_document
              return
            when :start_element
              el = @build_context = @build_context.add_element( event[1] )
              event[2].each do |key, value|
                el.attributes[key]=Attribute.new(key,value,self)
              end
            when :end_element
              @build_context = @build_context.parent
            when :text
              if @build_context[-1].instance_of? Text
                @build_context[-1] << event[1]
              else
                @build_context.add(
                  Text.new(event[1], @build_context.whitespace, nil, true)
                ) unless (
                  @build_context.ignore_whitespace_nodes and
                  event[1].strip.size==0
                )
              end
            when :comment
              c = Comment.new( event[1] )
              @build_context.add( c )
            when :cdata
              c = CData.new( event[1] )
              @build_context.add( c )
            when :processing_instruction
              @build_context.add( Instruction.new( event[1], event[2] ) )
            when :end_doctype
              entities.each { |k,v| entities[k] = @build_context.entities[k].value }
              @build_context = @build_context.parent
            when :start_doctype
              doctype = DocType.new( event[1..-1], @build_context )
              @build_context = doctype
              entities = {}
            when :attlistdecl
              n = AttlistDecl.new( event[1..-1] )
              @build_context.add( n )
            when :externalentity
              n = ExternalEntity.new( event[1] )
              @build_context.add( n )
            when :elementdecl
              n = ElementDecl.new( event[1] )
              @build_context.add(n)
            when :entitydecl
              entities[ event[1] ] = event[2] unless event[2] =~ /PUBLIC|SYSTEM/
              @build_context.add(Entity.new(event))
            when :notationdecl
              n = NotationDecl.new( *event[1..-1] )
              @build_context.add( n )
            when :xmldecl
              x = XMLDecl.new( event[1], event[2], event[3] )
              @build_context.add( x )
            end
          end
        rescue REXML::Validation::ValidationException
          raise
        rescue REXML::ParseException
          raise
        rescue
          raise ParseException.new( $!.message, @parser.source, @parser, $! )
        end
      end
    end
  end
end
