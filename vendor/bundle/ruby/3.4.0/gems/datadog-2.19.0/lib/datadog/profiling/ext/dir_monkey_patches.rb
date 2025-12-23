# frozen_string_literal: true

module Datadog
  module Profiling
    # Monkey patches needed for profiler features and compatibility
    module Ext
      # All Ruby versions as of this writing have bugs in the dir class implementation, causing issues such as
      # https://github.com/DataDog/dd-trace-rb/issues/3450 .
      # See also https://bugs.ruby-lang.org/issues/20586 for more details.
      #
      # This monkey patch for the Ruby `Dir` class works around these bugs for affected Ruby versions by temporarily
      # blocking the profiler from interrupting system calls.
      #
      # A lot of these APIs do very similar things -- they're provided by Ruby as helpers so users don't need to keep
      # reimplementing them but share the same underlying buggy code. And so our monkey patches are a bit repetitive
      # as well.
      # We don't DRY out this file to have minimal overhead.
      #
      # These monkey patches are applied by the profiler when the "dir_interruption_workaround_enabled" setting is
      # enabled. See the profiling settings for more detail.
      module DirMonkeyPatches
        def self.apply!
          ::Dir.singleton_class.prepend(Datadog::Profiling::Ext::DirClassMonkeyPatches)
          ::Dir.prepend(Datadog::Profiling::Ext::DirInstanceMonkeyPatches)

          true
        end
      end

      if RUBY_VERSION.start_with?("2.")
        # Monkey patches for Dir.singleton_class (Ruby 2 version). See DirMonkeyPatches above for more details.
        module DirClassMonkeyPatches
          def [](*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def children(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          # NOTE: When wrapping methods that yield, it's OK if the `yield` raises an exception while signals are
          # enabled. This is because:
          # * We can call `_native_resume_signals` many times in a row, both because it's idempotent, as well as it's
          #   very low overhead (see benchmarks/profiler_hold_resume_interruptions.rb)
          # * When an exception is being raised, the iteration will stop anyway, so there's no longer a concern of a
          #   signal causing Ruby to return an incorrect value
          def each_child(*args, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          def empty?(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def entries(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          # See note on methods that yield above.
          def foreach(*args, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          # See note on methods that yield above.
          def glob(*args, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              begin
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super
              ensure
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            end
          end

          def home(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end
        end
      else
        # Monkey patches for Dir.singleton_class (Ruby 3 version). See DirMonkeyPatches above for more details.
        module DirClassMonkeyPatches
          def [](*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def children(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          # See note on methods that yield above.
          def each_child(*args, **kwargs, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          def empty?(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def entries(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          # See note on methods that yield above.
          def foreach(*args, **kwargs, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          # See note on methods that yield above.
          def glob(*args, **kwargs, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              begin
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super
              ensure
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            end
          end

          def home(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end
        end
      end

      if RUBY_VERSION.start_with?("2.")
        # Monkey patches for Dir (Ruby 2 version). See DirMonkeyPatches above for more details.
        module DirInstanceMonkeyPatches
          # See note on methods that yield above.
          def each(*args, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals # <-- End critical region
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          unless RUBY_VERSION.start_with?("2.5.") # This is Ruby 2.6+
            # See note on methods that yield above.
            def each_child(*args, &block)
              if block
                begin
                  # <-- Begin critical region
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                  super do |entry_name|
                    Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                    # <-- We're safe now while running customer code
                    yield entry_name
                    # <-- We'll go back to the Dir internals, critical region again
                    Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                  end
                ensure
                  # <-- End critical region
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                end
              else
                # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
                # other branch once it gets going.
                super
              end
            end

            def children(*args, &block)
              Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
              super
            ensure
              Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
            end
          end

          def tell(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def pos(*args, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end
        end
      else
        # Monkey patches for Dir (Ruby 3 version). See DirMonkeyPatches above for more details.
        module DirInstanceMonkeyPatches
          # See note on methods that yield above.
          def each(*args, **kwargs, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals # <-- End critical region
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          # See note on methods that yield above.
          def each_child(*args, **kwargs, &block)
            if block
              begin
                # <-- Begin critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                super do |entry_name|
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
                  # <-- We're safe now while running customer code
                  yield entry_name
                  # <-- We'll go back to the Dir internals, critical region again
                  Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
                end
              ensure
                # <-- End critical region
                Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
              end
            else
              # This returns an enumerator. We don't want/need to intercede here, the enumerator will eventually call the
              # other branch once it gets going.
              super
            end
          end

          def children(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def tell(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end

          def pos(*args, **kwargs, &block)
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_hold_signals
            super
          ensure
            Datadog::Profiling::Collectors::CpuAndWallTimeWorker._native_resume_signals
          end
        end
      end
    end
  end
end
