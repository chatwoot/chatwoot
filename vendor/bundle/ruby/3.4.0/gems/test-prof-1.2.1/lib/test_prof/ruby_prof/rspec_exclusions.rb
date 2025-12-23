# frozen_string_literal: true

module TestProf
  module RubyProf
    # Generates the list of RSpec (framework internal) methods
    # to exclude from profiling
    module RSpecExclusions
      module_function

      def generate
        {
          RSpec::Core::Runner => %i[
            run
            run_specs
          ],

          RSpec::Core::ExampleGroup => %i[
            run
            run_examples
          ],

          RSpec::Core::ExampleGroup.singleton_class => %i[
            run
            run_examples
          ],

          RSpec::Core::Example => %i[
            run
            with_around_and_singleton_context_hooks
            with_around_example_hooks
            instance_exec
            run_before_example
          ],

          RSpec::Core::Example.singleton_class => %i[
            run
            with_around_and_singleton_context_hooks
            with_around_example_hooks
          ],

          RSpec::Core::Example::Procsy => [
            :call
          ],

          RSpec::Core::Hooks::HookCollections => %i[
            run
            run_around_example_hooks_for
            run_example_hooks_for
            run_owned_hooks_for
          ],

          RSpec::Core::Hooks::BeforeHook => [
            :run
          ],

          RSpec::Core::Hooks::AroundHook => [
            :execute_with
          ],

          RSpec::Core::Configuration => [
            :with_suite_hooks
          ],

          RSpec::Core::Reporter => [
            :report
          ]
        }.tap do |data|
          if defined?(RSpec::Support::ReentrantMutex)
            data[RSpec::Support::ReentrantMutex] = [
              :synchronize
            ]
          end

          if defined?(RSpec::Core::MemoizedHelpers::ThreadsafeMemoized)
            data.merge!(
              RSpec::Core::MemoizedHelpers::ThreadsafeMemoized => [
                :fetch_or_store
              ],

              RSpec::Core::MemoizedHelpers::NonThreadSafeMemoized => [
                :fetch_or_store
              ],

              RSpec::Core::MemoizedHelpers::ContextHookMemoized => [
                :fetch_or_store
              ]
            )
          end
        end
      end
    end
  end
end
