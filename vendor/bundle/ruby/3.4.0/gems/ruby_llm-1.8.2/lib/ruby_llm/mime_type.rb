# frozen_string_literal: true

require 'marcel'

module RubyLLM
  # MimeTypes module provides methods to handle MIME types using Marcel gem
  module MimeType
    module_function

    def for(...)
      Marcel::MimeType.for(...)
    end

    def image?(type)
      type.start_with?('image/')
    end

    def video?(type)
      type.start_with?('video/')
    end

    def audio?(type)
      type.start_with?('audio/')
    end

    def pdf?(type)
      type == 'application/pdf'
    end

    def text?(type)
      type.start_with?('text/') ||
        TEXT_SUFFIXES.any? { |suffix| type.end_with?(suffix) } ||
        NON_TEXT_PREFIX_TEXT_MIME_TYPES.include?(type)
    end

    # MIME types that have a text/ prefix but need to be handled differently
    TEXT_SUFFIXES = ['+json', '+xml', '+html', '+yaml', '+csv', '+plain', '+javascript', '+svg'].freeze

    # MIME types that don't have a text/ prefix but should be treated as text
    NON_TEXT_PREFIX_TEXT_MIME_TYPES = [
      'application/json', # Base type, even if specific ones end with +json
      'application/xml',  # Base type, even if specific ones end with +xml
      'application/javascript',
      'application/ecmascript',
      'application/rtf',
      'application/sql',
      'application/x-sh',
      'application/x-csh',
      'application/x-httpd-php',
      'application/sdp',
      'application/sparql-query',
      'application/graphql',
      'application/yang', # Data modeling language, often serialized as XML/JSON but the type itself is distinct
      'application/mbox', # Mailbox format
      'application/x-tex',
      'application/x-latex',
      'application/x-perl',
      'application/x-python',
      'application/x-tcl',
      'application/pgp-signature', # Often ASCII armored
      'application/pgp-keys',      # Often ASCII armored
      'application/vnd.coffeescript',
      'application/vnd.dart',
      'application/vnd.oai.openapi', # Base for OpenAPI, often with +json or +yaml suffix
      'application/vnd.zul',         # ZK User Interface Language (can be XML-like)
      'application/x-yaml',          # Common non-standard for YAML
      'application/yaml',            # Standard for YAML
      'application/toml'             # TOML configuration files
    ].freeze
  end
end
