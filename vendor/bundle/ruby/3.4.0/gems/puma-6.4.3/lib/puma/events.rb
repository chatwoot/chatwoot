# frozen_string_literal: true

module Puma

  # This is an event sink used by `Puma::Server` to handle
  # lifecycle events such as :on_booted, :on_restart, and :on_stopped.
  # Using `Puma::DSL` it is possible to register callback hooks
  # for each event type.
  class Events

    def initialize
      @hooks = Hash.new { |h,k| h[k] = [] }
    end

    # Fire callbacks for the named hook
    def fire(hook, *args)
      @hooks[hook].each { |t| t.call(*args) }
    end

    # Register a callback for a given hook
    def register(hook, obj=nil, &blk)
      if obj and blk
        raise "Specify either an object or a block, not both"
      end

      h = obj || blk

      @hooks[hook] << h

      h
    end

    def on_booted(&block)
      register(:on_booted, &block)
    end

    def on_restart(&block)
      register(:on_restart, &block)
    end

    def on_stopped(&block)
      register(:on_stopped, &block)
    end

    def fire_on_booted!
      fire(:on_booted)
    end

    def fire_on_restart!
      fire(:on_restart)
    end

    def fire_on_stopped!
      fire(:on_stopped)
    end
  end
end
