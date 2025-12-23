require 'spec_helper'

describe SCSSLint::Reporter do
  class SCSSLint::Reporter::FakeReporter < SCSSLint::Reporter; end

  describe '#descendants' do
    it 'contains FakeReporter' do
      SCSSLint::Reporter.descendants.should include(SCSSLint::Reporter::FakeReporter)
    end
  end
end
