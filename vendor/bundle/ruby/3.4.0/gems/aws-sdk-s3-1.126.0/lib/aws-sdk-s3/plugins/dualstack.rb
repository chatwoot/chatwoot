# frozen_string_literal: true

module Aws
  module S3
    module Plugins
      # @api private
      class Dualstack < Seahorse::Client::Plugin
        def add_handlers(handlers, _config)
          handlers.add(OptionHandler, step: :initialize)
        end

        # @api private
        class OptionHandler < Seahorse::Client::Handler
          def call(context)
            # Support client configuration and per-operation configuration
            if context.params.is_a?(Hash)
              dualstack = context.params.delete(:use_dualstack_endpoint)
            end
            dualstack = context.config.use_dualstack_endpoint if dualstack.nil?
            context[:use_dualstack_endpoint] = dualstack
            @handler.call(context)
          end
        end
      end
    end
  end
end
