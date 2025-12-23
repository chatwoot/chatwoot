# Code copied from https://github.com/celluloid/celluloid-fsm
module SassListen
  module FSM
    DEFAULT_STATE = :default # Default state name unless one is explicitly set

    # Included hook to extend class methods
    def self.included(klass)
      klass.send :extend, ClassMethods
    end

    module ClassMethods
      # Obtain or set the default state
      # Passing a state name sets the default state
      def default_state(new_default = nil)
        if new_default
          @default_state = new_default.to_sym
        else
          defined?(@default_state) ? @default_state : DEFAULT_STATE
        end
      end

      # Obtain the valid states for this FSM
      def states
        @states ||= {}
      end

      # Declare an FSM state and optionally provide a callback block to fire
      # Options:
      # * to: a state or array of states this state can transition to
      def state(*args, &block)
        if args.last.is_a? Hash
          # Stringify keys :/
          options = args.pop.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
        else
          options = {}
        end

        args.each do |name|
          name = name.to_sym
          default_state name if options['default']
          states[name] = State.new(name, options['to'], &block)
        end
      end
    end

    # Be kind and call super if you must redefine initialize
    def initialize
      @state = self.class.default_state
    end

    # Obtain the current state of the FSM
    attr_reader :state

    def transition(state_name)
      new_state = validate_and_sanitize_new_state(state_name)
      return unless new_state
      transition_with_callbacks!(new_state)
    end

    # Immediate state transition with no checks, or callbacks. "Dangerous!"
    def transition!(state_name)
      @state = state_name
    end

    protected

    def validate_and_sanitize_new_state(state_name)
      state_name = state_name.to_sym

      return if current_state_name == state_name

      if current_state && !current_state.valid_transition?(state_name)
        valid = current_state.transitions.map(&:to_s).join(', ')
        msg = "#{self.class} can't change state from '#{@state}'"\
          " to '#{state_name}', only to: #{valid}"
        fail ArgumentError, msg
      end

      new_state = states[state_name]

      unless new_state
        return if state_name == default_state
        fail ArgumentError, "invalid state for #{self.class}: #{state_name}"
      end

      new_state
    end

    def transition_with_callbacks!(state_name)
      transition! state_name.name
      state_name.call(self)
    end

    def states
      self.class.states
    end

    def default_state
      self.class.default_state
    end

    def current_state
      states[@state]
    end

    def current_state_name
      current_state && current_state.name || ''
    end

    class State
      attr_reader :name, :transitions

      def initialize(name, transitions = nil, &block)
        @name, @block = name, block
        @transitions = nil
        @transitions = Array(transitions).map(&:to_sym) if transitions
      end

      def call(obj)
        obj.instance_eval(&@block) if @block
      end

      def valid_transition?(new_state)
        # All transitions are allowed unless expressly
        return true unless @transitions

        @transitions.include? new_state.to_sym
      end
    end
  end
end
