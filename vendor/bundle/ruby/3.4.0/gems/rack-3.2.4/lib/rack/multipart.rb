# frozen_string_literal: true

require_relative 'constants'
require_relative 'utils'

require_relative 'multipart/parser'
require_relative 'multipart/generator'

require_relative 'bad_request'

module Rack
  # A multipart form data parser, adapted from IOWA.
  #
  # Usually, Rack::Request#POST takes care of calling this.
  module Multipart
    MULTIPART_BOUNDARY = "AaB03x"

    class MissingInputError < StandardError
      include BadRequest
    end

    # Accumulator for multipart form data, conforming to the QueryParser API.
    # In future, the Parser could return the pair list directly, but that would
    # change its API.
    class ParamList # :nodoc:
      def self.make_params
        new
      end

      def self.normalize_params(params, key, value)
        params << [key, value]
      end

      def initialize
        @pairs = []
      end

      def <<(pair)
        @pairs << pair
      end

      def to_params_hash
        @pairs
      end
    end

    class << self
      def parse_multipart(env, params = Rack::Utils.default_query_parser)
        unless io = env[RACK_INPUT]
          raise MissingInputError, "Missing input stream!"
        end

        if content_length = env['CONTENT_LENGTH']
          content_length = content_length.to_i
        end

        content_type = env['CONTENT_TYPE']

        tempfile = env[RACK_MULTIPART_TEMPFILE_FACTORY] || Parser::TEMPFILE_FACTORY
        bufsize = env[RACK_MULTIPART_BUFFER_SIZE] || Parser::BUFSIZE

        info = Parser.parse(io, content_length, content_type, tempfile, bufsize, params)
        env[RACK_TEMPFILES] = info.tmp_files

        return info.params
      end

      def extract_multipart(request, params = Rack::Utils.default_query_parser)
        parse_multipart(request.env)
      end

      def build_multipart(params, first = true)
        Generator.new(params, first).dump
      end
    end
  end
end
