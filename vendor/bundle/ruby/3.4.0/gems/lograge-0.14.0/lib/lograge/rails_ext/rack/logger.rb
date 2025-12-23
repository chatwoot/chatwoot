# frozen_string_literal: true

require 'active_support'
require 'active_support/concern'
require 'rails/rack/logger'

module Rails
  module Rack
    # Overwrites defaults of Rails::Rack::Logger that cause
    # unnecessary logging.
    # This effectively removes the log lines from the log
    # that say:
    # Started GET / for 192.168.2.1...
    class Logger
      # Overwrites Rails code that logs new requests
      def call_app(*args)
        env = args.last
        status, headers, body = @app.call(env)
        # needs to have same return type as the Rails builtins being overridden, see https://github.com/roidrage/lograge/pull/333
        # https://github.com/rails/rails/blob/be9d34b9bcb448b265114ebc28bef1a5b5e4c272/railties/lib/rails/rack/logger.rb#L37
        [status, headers, ::Rack::BodyProxy.new(body) {}] # rubocop:disable Lint/EmptyBlock
      ensure
        ActiveSupport::LogSubscriber.flush_all!
      end

      # Overwrites Rails 3.0/3.1 code that logs new requests
      def before_dispatch(_env); end
    end
  end
end
