require "active_support/backtrace_cleaner"
require "active_support/core_ext/string/access"

module Sentry
  module Rails
    class BacktraceCleaner < ActiveSupport::BacktraceCleaner
      APP_DIRS_PATTERN = /\A(?:\.\/)?(?:app|config|lib|test|\(\w*\))/.freeze
      RENDER_TEMPLATE_PATTERN = /:in `.*_\w+_{2,3}\d+_\d+'/.freeze

      def initialize
        super
        # we don't want any default silencers because they're too aggressive
        remove_silencers!

        @root = "#{Sentry.configuration.project_root}/"
        add_filter do |line|
          line.start_with?(@root) ? line.from(@root.size) : line
        end
        add_filter do |line|
          if line =~ RENDER_TEMPLATE_PATTERN
            line.sub(RENDER_TEMPLATE_PATTERN, "")
          else
            line
          end
        end
      end
    end
  end
end
