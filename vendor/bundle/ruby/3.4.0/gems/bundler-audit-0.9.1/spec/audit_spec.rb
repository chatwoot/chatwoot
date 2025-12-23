require 'spec_helper'
require 'bundler/audit'

describe Bundler::Audit do
  it "should have a VERSION constant" do
    expect(subject.const_get('VERSION')).not_to be_empty
  end
end
