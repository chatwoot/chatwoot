# frozen_string_literal: true

# Code copied from https://github.com/celluloid/celluloid-fsm

require 'thread'

module Listen
  module FSM
    # Included hook to extend class methods
    def self.included(klass)
      klass.send :extend, ClassMethods
    end

    module ClassMethods
      # Obtain or set the start state
      # Passing a state name sets the start state
      def start_state(new_start_state = nil)
        if new_start_state
          new_start_state.is_a?(Symbol) or raise ArgumentError, "state name must be a Symbol (got #{new_start_state.inspect})"
          @start_state = new_start_state
        else
          defined?(@start_state) or raise ArgumentError, "`start_state :<state>` must be declared before `new`"
          @start_state
        end
      end

      # The valid states for this FSM, as a hash with state name symbols as keys and State objects as values.
      def states
        @states ||= {}
      end

      # Declare an FSM state and optionally provide a callback block to fire on state entry
      # Options:
      # * to: a state or array of states this state can transition to
      def state(state_name, to: nil, &block)
        state_name.is_a?(Symbol) or raise ArgumentError, "state name must be a Symbol (got #{state_name.inspect})"
        states[state_name] = State.new(state_name, to, &block)
      end
    end

    # Note: including classes must call initialize_fsm from their initialize method.
    def initialize_fsm
      @fsm_initialized = true
      @state = self.class.start_state
      @mutex = ::Mutex.new
      @state_changed = ::ConditionVariable.new
    end

    # Current state of the FSM, stored as a symbol
    attr_reader :state

    # checks for one of the given states to wait for
    # if not already, waits for a state change (up to timeout seconds--`nil` means infinite)
    # returns truthy iff the transition to one of the desired state has occurred
    def wait_for_state(*wait_for_states, timeout: nil)
      wait_for_states.each do |state|
        state.is_a?(Symbol) or raise ArgumentError, "states must be symbols (got #{state.inspect})"
      end
      @mutex.synchronize do
        if !wait_for_states.include?(@state)
          @state_changed.wait(@mutex, timeout)
        end
        wait_for_states.include?(@state)
      end
    end

    private

    def transition(new_state_name)
      new_state_name.is_a?(Symbol) or raise ArgumentError, "state name must be a Symbol (got #{new_state_name.inspect})"
      if (new_state = validate_and_sanitize_new_state(new_state_name))
        transition_with_callbacks!(new_state)
      end
    end

    # Low-level, immediate state transition with no checks or callbacks.
    def transition!(new_state_name)
      new_state_name.is_a?(Symbol) or raise ArgumentError, "state name must be a Symbol (got #{new_state_name.inspect})"
      @fsm_initialized or raise ArgumentError, "FSM not initialized. You must call initialize_fsm from initialize!"
      @mutex.synchronize do
        yield if block_given?
        @state = new_state_name
        @state_changed.broadcast
      end
    end

    def validate_and_sanitize_new_state(new_state_name)
      return nil if @state == new_state_name

      if current_state && !current_state.valid_transition?(new_state_name)
        valid = current_state.transitions.map(&:to_s).join(', ')
        msg = "#{self.class} can't change state from '#{@state}' to '#{new_state_name}', only to: #{valid}"
        raise ArgumentError, msg
      end

      unless (new_state = self.class.states[new_state_name])
        new_state_name == self.class.start_state or raise ArgumentError, "invalid state for #{self.class}: #{new_state_name}"
      end

      new_state
    end

    def transition_with_callbacks!(new_state)
      transition! new_state.name
      new_state.call(self)
    end

    def current_state
      self.class.states[@state]
    end

    class State
      attr_reader :name, :transitions

      def initialize(name, transitions, &block)
        @name = name
        @block = block
        @transitions = if transitions
          Array(transitions).map(&:to_sym)
        end
      end

      def call(obj)
        obj.instance_eval(&@block) if @block
      end

      def valid_transition?(new_state)
        # All transitions are allowed if none are expressly declared
        !@transitions || @transitions.include?(new_state.to_sym)
      end
    end
  end
end
