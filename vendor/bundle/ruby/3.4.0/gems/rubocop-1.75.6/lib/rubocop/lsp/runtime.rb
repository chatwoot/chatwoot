# frozen_string_literal: true

require_relative 'diagnostic'
require_relative 'stdin_runner'

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
  module LSP
    # Runtime for Language Server Protocol of RuboCop.
    # @api private
    class Runtime
      attr_writer :safe_autocorrect, :lint_mode, :layout_mode

      def initialize(config_store)
        RuboCop::LSP.enable

        @runner = RuboCop::Lsp::StdinRunner.new(config_store)
        @cop_registry = RuboCop::Cop::Registry.global.to_h

        @safe_autocorrect = true
        @lint_mode = false
        @layout_mode = false
      end

      def format(path, text, command:, prism_result: nil)
        safe_autocorrect = if command
                             command == 'rubocop.formatAutocorrects'
                           else
                             @safe_autocorrect
                           end

        formatting_options = { autocorrect: true, safe_autocorrect: safe_autocorrect }
        formatting_options[:only] = config_only_options if @lint_mode || @layout_mode

        @runner.run(path, text, formatting_options, prism_result: prism_result)
        @runner.formatted_source
      end

      def offenses(path, text, document_encoding = nil, prism_result: nil)
        diagnostic_options = {}
        diagnostic_options[:only] = config_only_options if @lint_mode || @layout_mode

        @runner.run(path, text, diagnostic_options, prism_result: prism_result)
        @runner.offenses.map do |offense|
          Diagnostic.new(
            document_encoding, offense, path, @cop_registry[offense.cop_name]&.first
          ).to_lsp_diagnostic(@runner.config_for_working_directory)
        end
      end

      private

      def config_only_options
        only_options = []
        only_options << 'Lint' if @lint_mode
        only_options << 'Layout' if @layout_mode
        only_options
      end
    end
  end
end
