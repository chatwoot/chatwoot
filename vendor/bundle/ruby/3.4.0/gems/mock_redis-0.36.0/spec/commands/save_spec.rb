require 'spec_helper'

describe '#save' do
  it "responds with 'OK'" do
    @redises.save.should == 'OK'
  end
end
