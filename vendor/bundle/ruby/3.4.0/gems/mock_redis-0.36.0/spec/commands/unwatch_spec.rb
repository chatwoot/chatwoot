require 'spec_helper'

describe '#unwatch' do
  it "responds with 'OK'" do
    @redises.unwatch.should == 'OK'
  end
end
