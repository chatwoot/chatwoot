require 'logger'
require 'sass-listen/logger'
require 'sass-listen/listener'

require 'sass-listen/internals/thread_pool'

# Always set up logging by default first time file is required
#
# NOTE: If you need to clear the logger completely, do so *after*
# requiring this file. If you need to set a custom logger,
# require the listen/logger file and set the logger before requiring
# this file.
SassListen.setup_default_logger_if_unset

# Won't print anything by default because of level - unless you've set
# LISTEN_GEM_DEBUGGING or provided your own logger with a high enough level
SassListen::Logger.info "SassListen loglevel set to: #{SassListen.logger.level}"
SassListen::Logger.info "SassListen version: #{SassListen::VERSION}"

module SassListen
  class << self
    # Listens to file system modifications on a either single directory or
    # multiple directories.
    #
    # @param (see SassListen::Listener#new)
    #
    # @yield [modified, added, removed] the changed files
    # @yieldparam [Array<String>] modified the list of modified files
    # @yieldparam [Array<String>] added the list of added files
    # @yieldparam [Array<String>] removed the list of removed files
    #
    # @return [SassListen::Listener] the listener
    #
    def to(*args, &block)
      @listeners ||= []
      Listener.new(*args, &block).tap do |listener|
        @listeners << listener
      end
    end

    # This is used by the `listen` binary to handle Ctrl-C
    #
    def stop
      Internals::ThreadPool.stop
      @listeners ||= []

      # TODO: should use a mutex for this
      @listeners.each do |listener|
        # call stop to halt the main loop
        listener.stop
      end
      @listeners = nil
    end
  end
end
