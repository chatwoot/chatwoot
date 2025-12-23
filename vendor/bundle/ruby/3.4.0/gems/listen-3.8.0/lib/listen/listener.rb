# frozen_string_literal: true

require 'English'

require 'listen/version'

require 'listen/backend'

require 'listen/silencer'
require 'listen/silencer/controller'

require 'listen/queue_optimizer'

require 'listen/fsm'

require 'listen/event/loop'
require 'listen/event/queue'
require 'listen/event/config'

require 'listen/listener/config'

module Listen
  class Listener
    include Listen::FSM

    # Initializes the directories listener.
    #
    # @param [String] directory the directories to listen to
    # @param [Hash] options the listen options (see Listen::Listener::Options)
    #
    # @yield [modified, added, removed] the changed files
    # @yieldparam [Array<String>] modified the list of modified files
    # @yieldparam [Array<String>] added the list of added files
    # @yieldparam [Array<String>] removed the list of removed files
    #
    # rubocop:disable Metrics/MethodLength
    def initialize(*dirs, &block)
      options = dirs.last.is_a?(Hash) ? dirs.pop : {}

      @config = Config.new(options)

      eq_config = Event::Queue::Config.new(@config.relative?)
      queue = Event::Queue.new(eq_config)

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

      initialize_fsm
    end
    # rubocop:enable Metrics/MethodLength

    start_state :initializing

    state :initializing, to: [:backend_started, :stopped]

    state :backend_started, to: [:processing_events, :stopped] do
      @backend.start
    end

    state :processing_events, to: [:paused, :stopped] do
      @processor.start
    end

    state :paused, to: [:processing_events, :stopped] do
      @processor.pause
    end

    state :stopped, to: [:backend_started] do
      @backend.stop # halt events ASAP
      @processor.stop
    end

    # Starts processing events and starts adapters
    # or resumes invoking callbacks if paused
    def start
      case state
      when :initializing
        transition :backend_started
        transition :processing_events
      when :paused
        transition :processing_events
      else
        raise ArgumentError, "cannot start from state #{state.inspect}"
      end
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

    def stopped?
      state == :stopped
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
  end
end
