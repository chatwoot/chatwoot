require 'rails_helper'

# The debug gem, loaded whole, puts a hook on every fork whose at_exit waits for all the
# children of the process (debug/local.rb, after_fork_parent). Sidekiq forks for the
# SidekiqAlive healthcheck, and `listen` keeps fsevent watchers running as children, so a
# Sidekiq in development said `Bye!` on SIGTERM and never exited (#750). Only the prelude
# is loaded: `debugger` still opens a session, and the hook comes with that session alone.
# rubocop:disable RSpec/DescribeClass
RSpec.describe 'the debug gem' do
  # rubocop:enable RSpec/DescribeClass
  it 'is loaded without its fork hook' do
    expect(Process.singleton_class.ancestors.map(&:name)).not_to include('DEBUGGER__::ForkInterceptor')
  end

  it 'still offers debugger' do
    expect(Kernel.private_method_defined?(:debugger) || Kernel.method_defined?(:debugger)).to be(true)
  end
end
