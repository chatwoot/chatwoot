require 'base64'
require 'bigdecimal'
require 'date'
require 'stringio'
require 'time'
require 'yaml'

module MultiXml # rubocop:disable ModuleLength
  class ParseError < StandardError; end
  class NoParserError < StandardError; end
  class DisallowedTypeError < StandardError
    def initialize(type)
      super "Disallowed type attribute: #{type.inspect}"
    end
  end

  unless defined?(REQUIREMENT_MAP)
    REQUIREMENT_MAP = [
      ['ox', :ox],
      ['libxml', :libxml],
      ['nokogiri', :nokogiri],
      ['rexml/document', :rexml],
      ['oga', :oga],
    ].freeze
  end

  CONTENT_ROOT = '__content__'.freeze unless defined?(CONTENT_ROOT)

  unless defined?(PARSING)
    float_proc = proc { |float| float.to_f }
    datetime_proc = proc { |time| Time.parse(time).utc rescue DateTime.parse(time).utc } # rubocop:disable RescueModifier

    PARSING = {
      'symbol'       => proc { |symbol| symbol.to_sym },
      'date'         => proc { |date| Date.parse(date) },
      'datetime'     => datetime_proc,
      'dateTime'     => datetime_proc,
      'integer'      => proc { |integer| integer.to_i },
      'float'        => float_proc,
      'double'       => float_proc,
      'decimal'      => proc { |number| BigDecimal(number) },
      'boolean'      => proc { |boolean| !%w(0 false).include?(boolean.strip) },
      'string'       => proc { |string| string.to_s },
      'yaml'         => proc { |yaml| YAML.load(yaml) rescue yaml }, # rubocop:disable RescueModifier
      'base64Binary' => proc { |binary| ::Base64.decode64(binary) },
      'binary'       => proc { |binary, entity| parse_binary(binary, entity) },
      'file'         => proc { |file, entity| parse_file(file, entity) },
    }.freeze
  end

  unless defined?(TYPE_NAMES)
    TYPE_NAMES = {
      'Symbol'     => 'symbol',
      'Integer'    => 'integer',
      'BigDecimal' => 'decimal',
      'Float'      => 'float',
      'TrueClass'  => 'boolean',
      'FalseClass' => 'boolean',
      'Date'       => 'date',
      'DateTime'   => 'datetime',
      'Time'       => 'datetime',
      'Array'      => 'array',
      'Hash'       => 'hash',
    }.freeze
  end

  DISALLOWED_XML_TYPES = %w(symbol yaml).freeze

  DEFAULT_OPTIONS = {
    :typecast_xml_value => true,
    :disallowed_types => DISALLOWED_XML_TYPES,
    :symbolize_keys => false,
  }.freeze

  class << self
    # Get the current parser class.
    def parser
      return @parser if defined?(@parser)
      self.parser = default_parser
      @parser
    end

    # The default parser based on what you currently
    # have loaded and installed. First checks to see
    # if any parsers are already loaded, then checks
    # to see which are installed if none are loaded.
    def default_parser
      return :ox if defined?(::Ox)
      return :libxml if defined?(::LibXML)
      return :nokogiri if defined?(::Nokogiri)
      return :oga if defined?(::Oga)

      REQUIREMENT_MAP.each do |library, parser|
        begin
          require library
          return parser
        rescue LoadError
          next
        end
      end
      raise(NoParserError.new("No XML parser detected. If you're using Rubinius and Bundler, try adding an XML parser to your Gemfile (e.g. libxml-ruby, nokogiri, or rubysl-rexml). For more information, see https://github.com/sferik/multi_xml/issues/42."))
    end

    # Set the XML parser utilizing a symbol, string, or class.
    # Supported by default are:
    #
    # * <tt>:libxml</tt>
    # * <tt>:nokogiri</tt>
    # * <tt>:ox</tt>
    # * <tt>:rexml</tt>
    # * <tt>:oga</tt>
    def parser=(new_parser)
      case new_parser
      when String, Symbol
        require "multi_xml/parsers/#{new_parser.to_s.downcase}"
        @parser = MultiXml::Parsers.const_get(new_parser.to_s.split('_').collect(&:capitalize).join('').to_s)
      when Class, Module
        @parser = new_parser
      else
        raise('Did not recognize your parser specification. Please specify either a symbol or a class.')
      end
    end

    # Parse an XML string or IO into Ruby.
    #
    # <b>Options</b>
    #
    # <tt>:symbolize_keys</tt> :: If true, will use symbols instead of strings for the keys.
    #
    # <tt>:disallowed_types</tt> :: Types to disallow from being typecasted. Defaults to `['yaml', 'symbol']`. Use `[]` to allow all types.
    #
    # <tt>:typecast_xml_value</tt> :: If true, won't typecast values for parsed document
    def parse(xml, options = {}) # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
      xml ||= ''

      options = DEFAULT_OPTIONS.merge(options)

      xml = xml.strip if xml.respond_to?(:strip)
      begin
        xml = StringIO.new(xml) unless xml.respond_to?(:read)

        char = xml.getc
        return {} if char.nil?
        xml.ungetc(char)

        hash = undasherize_keys(parser.parse(xml) || {})
        hash = options[:typecast_xml_value] ? typecast_xml_value(hash, options[:disallowed_types]) : hash
      rescue DisallowedTypeError
        raise
      rescue parser.parse_error => error
        raise(ParseError, error.message, error.backtrace) # rubocop:disable RaiseArgs
      end
      hash = symbolize_keys(hash) if options[:symbolize_keys]
      hash
    end

    # This module decorates files with the <tt>original_filename</tt>
    # and <tt>content_type</tt> methods.
    module FileLike #:nodoc:
      attr_writer :original_filename, :content_type

      def original_filename
        @original_filename || 'untitled'
      end

      def content_type
        @content_type || 'application/octet-stream'
      end
    end

  private

    # TODO: Add support for other encodings
    def parse_binary(binary, entity) #:nodoc:
      case entity['encoding']
      when 'base64'
        Base64.decode64(binary)
      else
        binary
      end
    end

    def parse_file(file, entity)
      f = StringIO.new(Base64.decode64(file))
      f.extend(FileLike)
      f.original_filename = entity['name']
      f.content_type = entity['content_type']
      f
    end

    def symbolize_keys(params)
      case params
      when Hash
        params.inject({}) do |result, (key, value)|
          result.merge(key.to_sym => symbolize_keys(value))
        end
      when Array
        params.collect { |value| symbolize_keys(value) }
      else
        params
      end
    end

    def undasherize_keys(params)
      case params
      when Hash
        params.inject({}) do |hash, (key, value)|
          hash[key.to_s.tr('-'.freeze, '_'.freeze)] = undasherize_keys(value)
          hash
        end
      when Array
        params.collect { |value| undasherize_keys(value) }
      else
        params
      end
    end

    def typecast_xml_value(value, disallowed_types = nil) # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
      disallowed_types ||= DISALLOWED_XML_TYPES

      case value
      when Hash
        if value.include?('type') && !value['type'].is_a?(Hash) && disallowed_types.include?(value['type'])
          raise(DisallowedTypeError.new(value['type']))
        end

        if value['type'] == 'array'

          # this commented-out suggestion helps to avoid the multiple attribute
          # problem, but it breaks when there is only one item in the array.
          #
          # from: https://github.com/jnunemaker/httparty/issues/102
          #
          # _, entries = value.detect { |k, v| k != 'type' && v.is_a?(Array) }

          # This attempt fails to consider the order that the detect method
          # retrieves the entries.
          # _, entries = value.detect {|key, _| key != 'type'}

          # This approach ignores attribute entries that are not convertable
          # to an Array which allows attributes to be ignored.
          _, entries = value.detect { |k, v| k != 'type' && (v.is_a?(Array) || v.is_a?(Hash)) }

          case entries
          when NilClass
            []
          when String
            [] if entries.strip.empty?
          when Array
            entries.collect { |entry| typecast_xml_value(entry, disallowed_types) }
          when Hash
            [typecast_xml_value(entries, disallowed_types)]
          else
            raise("can't typecast #{entries.class.name}: #{entries.inspect}")
          end

        elsif value.key?(CONTENT_ROOT)
          content = value[CONTENT_ROOT]
          block = PARSING[value['type']]
          if block
            if block.arity == 1
              value.delete('type') if PARSING[value['type']]
              if value.keys.size > 1
                value[CONTENT_ROOT] = block.call(content)
                value
              else
                block.call(content)
              end
            else
              block.call(content, value)
            end
          else
            value.keys.size > 1 ? value : content
          end
        elsif value['type'] == 'string' && value['nil'] != 'true'
          ''
        # blank or nil parsed values are represented by nil
        elsif value.empty? || value['nil'] == 'true'
          nil
        # If the type is the only element which makes it then
        # this still makes the value nil, except if type is
        # a XML node(where type['value'] is a Hash)
        elsif value['type'] && value.size == 1 && !value['type'].is_a?(Hash)
          nil
        else
          xml_value = value.inject({}) do |hash, (k, v)|
            hash[k] = typecast_xml_value(v, disallowed_types)
            hash
          end

          # Turn {:files => {:file => #<StringIO>} into {:files => #<StringIO>} so it is compatible with
          # how multipart uploaded files from HTML appear
          xml_value['file'].is_a?(StringIO) ? xml_value['file'] : xml_value
        end
      when Array
        value.map! { |i| typecast_xml_value(i, disallowed_types) }
        value.length > 1 ? value : value.first
      when String
        value
      else
        raise("can't typecast #{value.class.name}: #{value.inspect}")
      end
    end
  end
end
