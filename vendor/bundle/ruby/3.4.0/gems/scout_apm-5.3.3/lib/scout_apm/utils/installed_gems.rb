module ScoutApm
  module Utils
    class InstalledGems
      attr_reader :context

      def initialize(context)
        @context = context
      end

      def logger
        context.logger
      end

      def run
        Bundler.rubygems.all_specs.map {|spec| [spec.name, spec.version.to_s] }
      rescue => e
        logger.warn("Couldn't fetch Gem information: #{e.message}")
        []
      end
    end
  end
end
