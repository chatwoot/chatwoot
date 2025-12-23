require 'spec_helper'

describe '#connected? [mock only]' do
  it 'returns true' do
    @redises.mock.connected?.should == true
  end
end
