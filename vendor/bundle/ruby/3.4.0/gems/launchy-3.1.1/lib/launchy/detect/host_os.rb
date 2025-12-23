# frozen_string_literal: true

require "rbconfig"

module Launchy
  module Detect
    # Internal: Determine the host operating system that Launchy is running on
    #
    class HostOs
      attr_reader :host_os
      alias to_s host_os
      alias to_str host_os

      def initialize(host_os = nil)
        @host_os = host_os

        return if @host_os

        if (@host_os = override_host_os)
          Launchy.log "Using LAUNCHY_HOST_OS override value of '#{Launchy.host_os}'"
        else
          @host_os = default_host_os
        end
      end

      def default_host_os
        ::RbConfig::CONFIG["host_os"].downcase
      end

      def override_host_os
        Launchy.host_os
      end
    end
  end
end
