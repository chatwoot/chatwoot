require 'spec_helper'

describe SCSSLint::Location do
  let(:engine) { described_class.new(css) }

  describe '#<=>' do
    let(:locations) do
      [
        SCSSLint::Location.new(2, 2, 2),
        SCSSLint::Location.new(2, 2, 1),
        SCSSLint::Location.new(2, 1, 2),
        SCSSLint::Location.new(2, 1, 1),
        SCSSLint::Location.new(1, 2, 2),
        SCSSLint::Location.new(1, 2, 1),
        SCSSLint::Location.new(1, 1, 2),
        SCSSLint::Location.new(1, 1, 1)
      ]
    end

    it 'allows locations to be sorted' do
      locations.sort.should == [
        SCSSLint::Location.new(1, 1, 1),
        SCSSLint::Location.new(1, 1, 2),
        SCSSLint::Location.new(1, 2, 1),
        SCSSLint::Location.new(1, 2, 2),
        SCSSLint::Location.new(2, 1, 1),
        SCSSLint::Location.new(2, 1, 2),
        SCSSLint::Location.new(2, 2, 1),
        SCSSLint::Location.new(2, 2, 2)
      ]
    end

    context 'when the same location is passed' do
      let(:location) { SCSSLint::Location.new(1, 1, 1) }
      let(:other_location) { SCSSLint::Location.new(1, 1, 1) }

      it 'returns 0' do
        (location <=> other_location).should == 0
      end
    end
  end
end
