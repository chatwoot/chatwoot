require 'spec_helper'

describe '#auth(password) [mock only]' do
  it "just returns 'OK'" do
    @redises.mock.auth('foo').should == 'OK'
  end
end
