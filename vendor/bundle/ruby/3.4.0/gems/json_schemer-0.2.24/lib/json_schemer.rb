# frozen_string_literal: true
require 'base64'
require 'bigdecimal'
require 'ipaddr'
require 'json'
require 'net/http'
require 'pathname'
require 'set'
require 'time'
require 'uri'

require 'ecma-re-validator'
require 'hana'
require 'regexp_parser'
require 'uri_template'

require 'json_schemer/version'
require 'json_schemer/format'
require 'json_schemer/errors'
require 'json_schemer/cached_resolver'
require 'json_schemer/schema/base'
require 'json_schemer/schema/draft4'
require 'json_schemer/schema/draft6'
require 'json_schemer/schema/draft7'

module JSONSchemer
  class UnsupportedMetaSchema < StandardError; end
  class UnknownRef < StandardError; end
  class InvalidRefResolution < StandardError; end
  class InvalidRegexpResolution < StandardError; end
  class InvalidFileURI < StandardError; end
  class InvalidSymbolKey < StandardError; end

  DRAFT_CLASS_BY_META_SCHEMA = {
    'http://json-schema.org/schema#' => Schema::Draft4, # Version-less $schema deprecated after Draft 4
    'http://json-schema.org/draft-04/schema#' => Schema::Draft4,
    'http://json-schema.org/draft-06/schema#' => Schema::Draft6,
    'http://json-schema.org/draft-07/schema#' => Schema::Draft7
  }.freeze

  DEFAULT_META_SCHEMA = 'http://json-schema.org/draft-07/schema#'

  WINDOWS_URI_PATH_REGEX = /\A\/[a-z]:/i

  FILE_URI_REF_RESOLVER = proc do |uri|
    raise InvalidFileURI, 'must use `file` scheme' unless uri.scheme == 'file'
    raise InvalidFileURI, 'cannot have a host (use `file:///`)' if uri.host && !uri.host.empty?
    path = uri.path
    path = path[1..-1] if path.match?(WINDOWS_URI_PATH_REGEX)
    JSON.parse(File.read(URI::DEFAULT_PARSER.unescape(path)))
  end

  class << self
    def schema(schema, **options)
      case schema
      when String
        schema = JSON.parse(schema)
      when Pathname
        uri = URI.parse(File.join('file:', URI::DEFAULT_PARSER.escape(schema.realpath.to_s)))
        if options.key?(:ref_resolver)
          schema = FILE_URI_REF_RESOLVER.call(uri)
        else
          ref_resolver = CachedResolver.new(&FILE_URI_REF_RESOLVER)
          schema = ref_resolver.call(uri)
          options[:ref_resolver] = ref_resolver
        end
        schema[draft_class(schema)::ID_KEYWORD] ||= uri.to_s
      end
      draft_class(schema).new(schema, **options)
    end

  private

    def draft_class(schema)
      meta_schema = schema.is_a?(Hash) && schema.key?('$schema') ? schema['$schema'] : DEFAULT_META_SCHEMA
      DRAFT_CLASS_BY_META_SCHEMA[meta_schema] || raise(UnsupportedMetaSchema, meta_schema)
    end
  end
end
