require 'English'

require 'sass-listen/version'

require 'sass-listen/backend'

require 'sass-listen/silencer'
require 'sass-listen/silencer/controller'

require 'sass-listen/queue_optimizer'

require 'sass-listen/fsm'

require 'sass-listen/event/loop'
require 'sass-listen/event/queue'
require 'sass-listen/event/config'

require 'sass-listen/listener/config'

module SassListen
  class Listener
    include SassListen::FSM

    # Initializes the directories listener.
    #
    # @param [String] directory the directories to listen to
    # @param [Hash] options the listen options (see SassListen::Listener::Options)
    #
    # @yield [modified, added, removed] the changed files
    # @yieldparam [Array<String>] modified the list of modified files
    # @yieldparam [Array<String>] added the list of added files
    # @yieldparam [Array<String>] removed the list of removed files
    #
    def initialize(*dirs, &block)
      options = dirs.last.is_a?(Hash) ? dirs.pop : {}

      @config = Config.new(options)

      eq_config = Event::Queue::Config.new(@config.relative?)
      queue = Event::Queue.new(eq_config) { @processor.wakeup_on_event }

      silencer = Silencer.new
      rules = @config.silencer_rules
      @silencer_controller = Silencer::Controller.new(silencer, rules)

      @backend = Backend.new(dirs, queue, silencer, @config)

      optimizer_config = QueueOptimizer::Config.new(@backend, silencer)

      pconfig = Event::Config.new(
        self,
        queue,
        QueueOptimizer.new(optimizer_config),
        @backend.min_delay_between_events,
        &block)

      @processor = Event::Loop.new(pconfig)

      super() # FSM
    end

    default_state :initializing

    state :initializing, to: [:backend_started, :stopped]

    state :backend_started, to: [:frontend_ready, :stopped] do
      backend.start
    end

    state :frontend_ready, to: [:processing_events, :stopped] do
      processor.setup
    end

    state :processing_events, to: [:paused, :stopped] do
      processor.resume
    end

    state :paused, to: [:processing_events, :stopped] do
      processor.pause
    end

    state :stopped, to: [:backend_started] do
      backend.stop # should be before processor.teardown to halt events ASAP
      processor.teardown
    end

    # Starts processing events and starts adapters
    # or resumes invoking callbacks if paused
    def start
      transition :backend_started if state == :initializing
      transition :frontend_ready if state == :backend_started
      transition :processing_events if state == :frontend_ready
      transition :processing_events if state == :paused
    end

    # Stops both listening for events and processing them
    def stop
      transition :stopped
    end

    # Stops invoking callbacks (messages pile up)
    def pause
      transition :paused
    end

    # processing means callbacks are called
    def processing?
      state == :processing_events
    end

    def paused?
      state == :paused
    end

    def ignore(regexps)
      @silencer_controller.append_ignores(regexps)
    end

    def ignore!(regexps)
      @silencer_controller.replace_with_bang_ignores(regexps)
    end

    def only(regexps)
      @silencer_controller.replace_with_only(regexps)
    end

    private

    attr_reader :processor
    attr_reader :backend
  end
end
