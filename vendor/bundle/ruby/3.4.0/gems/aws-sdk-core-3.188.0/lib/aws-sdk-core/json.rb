# frozen_string_literal: true

require 'json'
require_relative 'json/builder'
require_relative 'json/error_handler'
require_relative 'json/handler'
require_relative 'json/parser'
require_relative 'json/json_engine'
require_relative 'json/oj_engine'

module Aws
  # @api private
  module Json
    class ParseError < StandardError
      def initialize(error)
        @error = error
        super(error.message)
      end

      attr_reader :error
    end

    class << self
      def load(json)
        ENGINE.load(json)
      end

      def load_file(path)
        load(File.open(path, 'r', encoding: 'UTF-8', &:read))
      end

      def dump(value)
        ENGINE.dump(value)
      end

      private

      def select_engine
        require 'oj'
        OjEngine
      rescue LoadError
        JSONEngine
      end
    end

    # @api private
    ENGINE = select_engine
  end
end
