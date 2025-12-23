require 'spec_helper'

describe '#zscan_each' do
  subject { MockRedis::Database.new(self) }

  let(:key) { 'mock-redis-test:zscan_each' }

  before do
    allow(subject).to receive(:zrange).and_return(collection)
  end

  context 'when no keys are found' do
    let(:collection) { [] }

    it 'does not iterate over any elements' do
      results = subject.zscan_each(key).map do |m, s|
        [m, s]
      end
      expect(results).to match_array(collection)
    end
  end

  context 'when keys are found' do
    context 'when no match filter is supplied' do
      let(:collection) { Array.new(20) { |i| ["m#{i}", i] } }

      it 'iterates over each item in the collection' do
        results = subject.zscan_each(key).map do |m, s|
          [m, s]
        end
        expect(results).to match_array(collection)
      end
    end

    context 'when giving a custom match filter' do
      let(:match) { 'm1*' }
      let(:collection) { Array.new(12) { |i| ["m#{i}", i] } }
      let(:expected) { [['m1', 1], ['m10', 10], ['m11', 11]] }

      it 'iterates over each item in the filtered collection' do
        results = subject.zscan_each(key, match: match).map do |m, s|
          [m, s]
        end
        expect(results).to match_array(expected)
      end
    end
  end
end
