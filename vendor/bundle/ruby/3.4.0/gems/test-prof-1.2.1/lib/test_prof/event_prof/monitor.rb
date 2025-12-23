# frozen_string_literal: true

module TestProf
  module EventProf
    # Wrap methods with instrumentation
    module Monitor
      class BaseTracker
        attr_reader :event

        def initialize(event)
          @event = event
        end

        def track
          TestProf::EventProf.instrumenter.instrument(event) { yield }
        end
      end

      class TopLevelTracker < BaseTracker
        attr_reader :id

        def initialize(event)
          super
          @id = :"event_prof_monitor_#{event}"
          Thread.current[id] = 0
        end

        def track
          Thread.current[id] += 1
          res = nil
          begin
            res =
              if Thread.current[id] == 1
                super { yield }
              else
                yield
              end
          ensure
            Thread.current[id] -= 1
          end
          res
        end
      end

      class << self
        def call(mod, event, *mids, guard: nil, top_level: false)
          tracker = top_level ? TopLevelTracker.new(event) : BaseTracker.new(event)

          patch = Module.new do
            mids.each do |mid|
              if RUBY_VERSION >= "2.7.0"
                define_method(mid) do |*args, **kwargs, &block|
                  next super(*args, **kwargs, &block) unless guard.nil? || instance_exec(*args, **kwargs, &guard)
                  tracker.track { super(*args, **kwargs, &block) }
                end
              else
                define_method(mid) do |*args, &block|
                  next super(*args, &block) unless guard.nil? || instance_exec(*args, &guard)
                  tracker.track { super(*args, &block) }
                end
              end
            end
          end

          mod.prepend(patch)
        end
      end
    end
  end
end
