require 'spec_helper'

describe '#ping' do
  it 'returns "PONG" with no arguments' do
    @redises.ping.should == 'PONG'
  end

  it 'returns the argument' do
    @redises.ping('HELLO').should == 'HELLO'
  end
end
