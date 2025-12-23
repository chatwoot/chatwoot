# frozen_string_literal: true

require_relative '../../rubocop/lsp/runtime'

module RubyLsp
  module RuboCop
    # Provides an adapter to bridge RuboCop's built-in LSP runtime with Ruby LSP's add-on.
    # @api private
    class RuntimeAdapter
      include RubyLsp::Requests::Support::Formatter

      def initialize
        config_store = ::RuboCop::ConfigStore.new

        @runtime = ::RuboCop::LSP::Runtime.new(config_store)
      end

      def run_diagnostic(uri, document)
        @runtime.offenses(
          uri_to_path(uri),
          document.source,
          document.encoding,
          prism_result: prism_result(document)
        )
      end

      def run_formatting(uri, document)
        @runtime.format(
          uri_to_path(uri),
          document.source,
          command: 'rubocop.formatAutocorrects',
          prism_result: prism_result(document)
        )
      end

      def run_range_formatting(_uri, _partial_source, _base_indentation)
        # Not yet supported. Should return the formatted version of `partial_source` which is
        # a partial selection of the entire document. For example, it should not try to add
        # a frozen_string_literal magic comment and all style corrections should start from
        # the `base_indentation`.
        nil
      end

      private

      # duplicated from: lib/standard/lsp/routes.rb
      # modified to incorporate Ruby LSP's to_standardized_path method
      def uri_to_path(uri)
        if uri.respond_to?(:to_standardized_path) && (standardized_path = uri.to_standardized_path)
          standardized_path
        else
          uri.to_s.delete_prefix('file://')
        end
      end

      def prism_result(document)
        prism_result = document.parse_result

        # NOTE: `prism_result` must be `Prism::ParseLexResult` compatible object.
        # This is for compatibility parsed result unsupported.
        prism_result.is_a?(Prism::ParseLexResult) ? prism_result : nil
      end
    end
  end
end
