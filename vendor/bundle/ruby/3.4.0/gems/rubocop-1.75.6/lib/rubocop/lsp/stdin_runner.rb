# frozen_string_literal: true

#
# This code is based on https://github.com/standardrb/standard.
#
# Copyright (c) 2023 Test Double, Inc.
#
# The MIT License (MIT)
#
# https://github.com/standardrb/standard/blob/main/LICENSE.txt
#
module RuboCop
  module Lsp
    # Originally lifted from:
    # https://github.com/Shopify/ruby-lsp/blob/8d4c17efce4e8ecc8e7c557ab2981db6b22c0b6d/lib/ruby_lsp/requests/support/rubocop_runner.rb#L20
    # @api private
    class StdinRunner < RuboCop::Runner
      class ConfigurationError < StandardError; end

      attr_reader :offenses, :config_for_working_directory

      DEFAULT_RUBOCOP_OPTIONS = {
        stderr: true,
        force_exclusion: true,
        formatters: ['RuboCop::Formatter::BaseFormatter'],
        raise_cop_error: true,
        todo_file: nil,
        todo_ignore_files: []
      }.freeze

      def initialize(config_store)
        @options = {}

        @offenses = []
        @warnings = []
        @errors = []

        @config_for_working_directory = config_store.for_pwd

        super(@options, config_store)
      end

      # rubocop:disable Metrics/MethodLength
      def run(path, contents, options, prism_result: nil)
        @options = options.merge(DEFAULT_RUBOCOP_OPTIONS)
        @options[:stdin] = contents

        @prism_result = prism_result

        @offenses = []
        @warnings = []
        @errors = []

        super([path])

        raise Interrupt if aborting?
      rescue RuboCop::Runner::InfiniteCorrectionLoop => e
        if defined?(::RubyLsp::Requests::Formatting::Error)
          raise ::RubyLsp::Requests::Formatting::Error, e.message
        end

        raise e
      rescue RuboCop::ValidationError => e
        raise ConfigurationError, e.message
      rescue StandardError => e
        if defined?(::RubyLsp::Requests::Formatting::Error)
          raise ::RubyLsp::Requests::Support::InternalRuboCopError, e
        end

        raise e
      end
      # rubocop:enable Metrics/MethodLength

      def formatted_source
        @options[:stdin]
      end

      private

      def file_finished(_file, offenses)
        @offenses = offenses
      end
    end
  end
end
