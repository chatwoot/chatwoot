# frozen_string_literal: true

require 'listen/adapter'
require 'listen/adapter/base'
require 'listen/adapter/config'

require 'forwardable'

# This class just aggregates configuration object to avoid Listener specs
# from exploding with huge test setup blocks
module Listen
  class Backend
    extend Forwardable

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

    delegate start: :adapter
    delegate stop: :adapter

    attr_reader :min_delay_between_events

    private

    attr_reader :adapter
  end
end
