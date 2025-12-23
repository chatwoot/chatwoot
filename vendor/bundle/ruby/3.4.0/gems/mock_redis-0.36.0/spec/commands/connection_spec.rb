require 'spec_helper'

describe '#connection' do
  let(:redis) { @redises.mock }

  it 'returns the correct values' do
    redis.connection.should == {
      :host => '127.0.0.1',
      :port => 6379,
      :db => 0,
      :id => 'redis://127.0.0.1:6379/0',
      :location => '127.0.0.1:6379'
    }
  end
end
