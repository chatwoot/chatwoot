require 'spec_helper'
require 'bundler/audit/results/result'

describe Bundler::Audit::Results::Result do
  describe "#to_h" do
    it do
      expect { subject.to_h }.to raise_error(NotImplementedError)
    end
  end
end
