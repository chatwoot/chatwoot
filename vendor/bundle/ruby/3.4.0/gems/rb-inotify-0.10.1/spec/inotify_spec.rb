require 'spec_helper'

describe INotify do
  describe "version" do
    it "exists" do
      expect(INotify::VERSION).to be_truthy
    end
  end
end
