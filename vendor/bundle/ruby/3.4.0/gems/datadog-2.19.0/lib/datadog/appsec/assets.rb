# frozen_string_literal: true

require 'pathname'

module Datadog
  module AppSec
    # Helper methods to get vendored assets
    module Assets
      module_function

      def waf_rules(kind = :recommended)
        read("waf_rules/#{kind}.json")
      end

      def waf_processors
        read('waf_rules/processors.json')
      end

      def waf_scanners
        read('waf_rules/scanners.json')
      end

      def blocked(format: :html)
        (@blocked ||= {})[format] ||= read("blocked.#{format}")
      end

      def path
        Pathname.new(dir).join('assets')
      end

      def filepath(filename)
        path.join(filename)
      end

      def read(filename, mode = 'rb')
        File.open(filepath(filename), mode) { |f| f.read || raise('Unexpected nil IO object') }
      end

      def dir
        # Happens only if this file is evaluated standalone, which should not happen
        # Necessary to make type-checker happy with a non-nilable return value
        __dir__ || raise('Unexpected file eval')
      end
    end
  end
end
