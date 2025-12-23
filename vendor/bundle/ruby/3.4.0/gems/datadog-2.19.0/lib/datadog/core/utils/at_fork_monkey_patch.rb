# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Monkey patches `Kernel#fork` and similar functions, adding an `at_fork` callback mechanism which
      # is used to restart observability after the VM forks (e.g. in multiprocess Ruby apps).
      module AtForkMonkeyPatch
        AT_FORK_CHILD_BLOCKS = [] # rubocop:disable Style/MutableConstant Used to store blocks to run, mutable by design.
        private_constant :AT_FORK_CHILD_BLOCKS

        def self.supported?
          Process.respond_to?(:fork)
        end

        def self.apply!
          return false unless supported?

          if RUBY_VERSION < '3.1'
            [
              ::Process.singleton_class, # Process.fork
              ::Kernel.singleton_class,  # Kernel.fork
              ::Object,                  # fork without explicit receiver (it's defined as a method in ::Kernel)
              # Note: Modifying Object as we do here is irreversible. During tests, this
              # change will stick around even if we otherwise stub `Process` and `Kernel`
            ].each { |target| target.prepend(KernelMonkeyPatch) }
          end

          ::Process.singleton_class.prepend(ProcessMonkeyPatch)

          true
        end

        def self.run_at_fork_blocks(stage)
          raise(ArgumentError, "Unsupported stage #{stage}") unless stage == :child

          AT_FORK_CHILD_BLOCKS.each(&:call)
        end

        def self.at_fork(stage, &block)
          raise(ArgumentError, "Unsupported stage #{stage}") unless stage == :child
          raise(ArgumentError, 'Missing block argument') unless block

          AT_FORK_CHILD_BLOCKS << block

          true
        end

        # Adds `at_fork` behavior; see parent module for details.
        module KernelMonkeyPatch
          def fork
            # If a block is provided, it must be wrapped to trigger callbacks.
            child_block = if block_given?
              proc do
                AtForkMonkeyPatch.run_at_fork_blocks(:child)

                # Invoke original block
                yield
              end
            end

            # Start fork
            # If a block is provided, use the wrapped version.
            result = child_block.nil? ? super : super(&child_block)

            # When fork gets called without a block, it returns twice:
            # If we're in the fork, result = nil: trigger child callbacks.
            # If we're in the parent, result = pid: we do nothing.
            # (If it gets called with a block, it only returns on the parent)
            AtForkMonkeyPatch.run_at_fork_blocks(:child) if result.nil?

            result
          end
        end

        # Adds `at_fork` behavior; see parent module for details.
        module ProcessMonkeyPatch
          # Hook provided by Ruby 3.1+ for observability libraries that want to know about fork, see
          # https://github.com/ruby/ruby/pull/5017 and https://bugs.ruby-lang.org/issues/17795
          def _fork
            pid = super

            AtForkMonkeyPatch.run_at_fork_blocks(:child) if pid == 0

            pid
          end

          # A call to Process.daemon ( https://rubyapi.org/3.1/o/process#method-c-daemon ) forks the current process and
          # keeps executing code in the child process, killing off the parent, thus effectively replacing it.
          # This is not covered by `_fork` and thus we have some extra code for it.
          def daemon(*args)
            result = super

            AtForkMonkeyPatch.run_at_fork_blocks(:child)

            result
          end
        end
      end
    end
  end
end
