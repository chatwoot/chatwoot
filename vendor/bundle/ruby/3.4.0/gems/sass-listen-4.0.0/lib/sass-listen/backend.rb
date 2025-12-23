require 'sass-listen/adapter'
require 'sass-listen/adapter/base'
require 'sass-listen/adapter/config'

require 'forwardable'

# This class just aggregates configuration object to avoid Listener specs
# from exploding with huge test setup blocks
module SassListen
  class Backend
    def initialize(directories, queue, silencer, config)
      adapter_select_opts = config.adapter_select_options

      adapter_class = Adapter.select(adapter_select_opts)

      # Use default from adapter if possible
      @min_delay_between_events = config.min_delay_between_events
      @min_delay_between_events ||= adapter_class::DEFAULTS[:wait_for_delay]
      @min_delay_between_events ||= 0.1

      adapter_opts = config.adapter_instance_options(adapter_class)

      aconfig = Adapter::Config.new(directories, queue, silencer, adapter_opts)
      @adapter = adapter_class.new(aconfig)
    end

    def start
      adapter.start
    end

    def stop
      adapter.stop
    end

    def min_delay_between_events
      @min_delay_between_events
    end

    private

    attr_reader :adapter
  end
end
