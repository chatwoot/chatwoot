# frozen_string_literal: true

require 'logger'
require 'weakref'
require 'listen/logger'
require 'listen/listener'

# Won't print anything by default because of level - unless you've set
# LISTEN_GEM_DEBUGGING or provided your own logger with a high enough level
Listen.logger.info "Listen loglevel set to: #{Listen.logger.level}"
Listen.logger.info "Listen version: #{Listen::VERSION}"

module Listen
  @listeners = Queue.new

  class << self
    # Listens to file system modifications on a either single directory or
    # multiple directories.
    #
    # @param (see Listen::Listener#new)
    #
    # @yield [modified, added, removed] the changed files
    # @yieldparam [Array<String>] modified the list of modified files
    # @yieldparam [Array<String>] added the list of added files
    # @yieldparam [Array<String>] removed the list of removed files
    #
    # @return [Listen::Listener] the listener
    #
    def to(*args, &block)
      Listener.new(*args, &block).tap do |listener|
        @listeners.enq(WeakRef.new(listener))
      end
    end

    # This is used by the `listen` binary to handle Ctrl-C
    #
    def stop
      while (listener = @listeners.deq(true))
        begin
          listener.stop
        rescue WeakRef::RefError
        end
      end
    rescue ThreadError
    end
  end
end
