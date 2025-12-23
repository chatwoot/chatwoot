require 'rexml/parsers/streamparser'
require 'rexml/parsers/baseparser'
require 'rexml/light/node'
require 'rexml/text'
require "rexml/document"
require 'date'
require 'time'
require 'yaml'
require 'bigdecimal'

# The Reason behind redefining the String Class for this specific plugin is to
# avoid the dynamic insertion of stuff on it (see version previous to this commit).
# Doing that disables the possibility of efectuating a dump on the structure. This way it goes.
class REXMLUtiliyNodeString < String
  attr_accessor :attributes
end

# This is a slighly modified version of the XMLUtilityNode from
# http://merb.devjavu.com/projects/merb/ticket/95 (has.sox@gmail.com)
# It's mainly just adding vowels, as I ht cd wth n vwls :)
# This represents the hard part of the work, all I did was change the
# underlying parser.
class REXMLUtilityNode #:nodoc:
  attr_accessor :name, :attributes, :children, :type

  def self.typecasts
    @@typecasts
  end

  def self.typecasts=(obj)
    @@typecasts = obj
  end

  def self.available_typecasts
    @@available_typecasts
  end

  def self.available_typecasts=(obj)
    @@available_typecasts = obj
  end

  self.typecasts = {}
  self.typecasts["integer"]       = lambda{|v| v.nil? ? nil : v.to_i}
  self.typecasts["boolean"]       = lambda{|v| v.nil? ? nil : (v.strip != "false")}
  self.typecasts["datetime"]      = lambda{|v| v.nil? ? nil : Time.parse(v).utc}
  self.typecasts["date"]          = lambda{|v| v.nil? ? nil : Date.parse(v)}
  self.typecasts["dateTime"]      = lambda{|v| v.nil? ? nil : Time.parse(v).utc}
  self.typecasts["decimal"]       = lambda{|v| v.nil? ? nil : BigDecimal(v.to_s)}
  self.typecasts["double"]        = lambda{|v| v.nil? ? nil : v.to_f}
  self.typecasts["float"]         = lambda{|v| v.nil? ? nil : v.to_f}
  self.typecasts["string"]        = lambda{|v| v.to_s}
  self.typecasts["base64Binary"]  = lambda{|v| v.unpack('m').first }

  self.available_typecasts = self.typecasts.keys

  def initialize(name, normalized_attributes = {})

    # unnormalize attribute values
    attributes = Hash[* normalized_attributes.map { |key, value|
      [ key, unnormalize_xml_entities(value) ]
    }.flatten]

    @name         = name.tr("-", "_")
    # leave the type alone if we don't know what it is
    @type         = self.class.available_typecasts.include?(attributes["type"]) ? attributes.delete("type") : attributes["type"]

    @nil_element  = attributes.delete("nil") == "true"
    @attributes   = undasherize_keys(attributes)
    @children     = []
    @text         = false
  end

  def add_node(node)
    @text = true if node.is_a? String
    @children << node
  end

  def to_hash
    # ACG: Added a check here to prevent an exception a type == "file" tag has nodes within it
    if @type == "file" and (@children.first.nil? or @children.first.is_a?(String))
      f = StringIO.new((@children.first || '').unpack('m').first)
      class << f
        attr_accessor :original_filename, :content_type
      end
      f.original_filename = attributes['name'] || 'untitled'
      f.content_type = attributes['content_type'] || 'application/octet-stream'
      return {name => f}
    end

    if @text
      t = typecast_value( unnormalize_xml_entities( inner_html ) )
      if t.is_a?(String)
        t = REXMLUtiliyNodeString.new(t)
        t.attributes = attributes
      end
      return { name => t }
    else
      #change repeating groups into an array
      groups = @children.inject({}) { |s,e| (s[e.name] ||= []) << e; s }

      out = nil
      if @type == "array"
        out = []
        groups.each do |k, v|
          if v.size == 1
            out << v.first.to_hash.entries.first.last
          else
            out << v.map{|e| e.to_hash[k]}
          end
        end
        out = out.flatten

      else # If Hash
        out = {}
        groups.each do |k,v|
          if v.size == 1
            out.merge!(v.first)
          else
            out.merge!( k => v.map{|e| e.to_hash[k]})
          end
        end
        out.merge! attributes unless attributes.empty?
        out = out.empty? ? nil : out
      end

      if @type && out.nil?
        { name => typecast_value(out) }
      else
        { name => out }
      end
    end
  end

  # Typecasts a value based upon its type. For instance, if
  # +node+ has #type == "integer",
  # {{[node.typecast_value("12") #=> 12]}}
  #
  # @param value<String> The value that is being typecast.
  #
  # @details [:type options]
  #   "integer"::
  #     converts +value+ to an integer with #to_i
  #   "boolean"::
  #     checks whether +value+, after removing spaces, is the literal
  #     "true"
  #   "datetime"::
  #     Parses +value+ using Time.parse, and returns a UTC Time
  #   "date"::
  #     Parses +value+ using Date.parse
  #
  # @return <Integer, TrueClass, FalseClass, Time, Date, Object>
  #   The result of typecasting +value+.
  #
  # @note
  #   If +self+ does not have a "type" key, or if it's not one of the
  #   options specified above, the raw +value+ will be returned.
  def typecast_value(value)
    return value unless @type
    proc = self.class.typecasts[@type]
    proc.nil? ? value : proc.call(value)
  end

  # Take keys of the form foo-bar and convert them to foo_bar
  def undasherize_keys(params)
    params.keys.each do |key, value|
      params[key.tr("-", "_")] = params.delete(key)
    end
    params
  end

  # Get the inner_html of the REXML node.
  def inner_html
    @children.join
  end

  # Converts the node into a readable HTML node.
  #
  # @return <String> The HTML node in text form.
  def to_html
    attributes.merge!(:type => @type ) if @type
    "<#{name}#{Crack::Util.to_xml_attributes(attributes)}>#{@nil_element ? '' : inner_html}</#{name}>"
  end

  # @alias #to_html #to_s
  def to_s
    to_html
  end

  private

  def unnormalize_xml_entities value
    REXML::Text.unnormalize(value)
  end
end

module Crack
  class REXMLParser
    def self.parse(xml)
      stack = []
      parser = REXML::Parsers::BaseParser.new(xml)

      while true
        event = parser.pull
        case event[0]
        when :end_document
          break
        when :end_doctype, :start_doctype
          # do nothing
        when :start_element
          stack.push REXMLUtilityNode.new(event[1], event[2])
        when :end_element
          if stack.size > 1
            temp = stack.pop
            stack.last.add_node(temp)
          end
        when :text, :cdata
          stack.last.add_node(event[1]) unless event[1].strip.length == 0 || stack.empty?
        end
      end

      stack.length > 0 ? stack.pop.to_hash : {}
    end
  end

  class XML
    def self.parser
      @@parser ||= REXMLParser
    end

    def self.parser=(parser)
      @@parser = parser
    end

    def self.parse(xml)
      parser.parse(xml)
    end
  end
end
