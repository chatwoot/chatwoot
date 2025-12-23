# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Start Language Server Protocol of RuboCop.
      # @api private
      class LSP < Base
        self.command_name = :lsp

        def run
          # Load on demand, `languge-server-protocol` is heavy to require.
          require_relative '../../lsp/server'
          RuboCop::LSP::Server.new(@config_store).start
        end
      end
    end
  end
end
