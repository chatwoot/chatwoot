require 'spec_helper'

describe '#quit' do
  it "responds with 'OK'" do
    @redises.quit.should == 'OK'
  end
end
