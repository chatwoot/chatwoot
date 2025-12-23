require 'spec_helper'

describe '#script(subcommand, *args)' do
  before { @key = 'mock-redis-test:script' }

  it 'works with load subcommand' do
    expect { @redises.send_without_checking(:script, :load, 'return 1') }.to_not raise_error
  end
end
