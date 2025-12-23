require 'spec_helper'

describe '#sscan_each' do
  subject { MockRedis::Database.new(self) }

  let(:key) { 'mock-redis-test:sscan_each' }

  before do
    allow(subject).to receive(:smembers).and_return(collection)
  end

  context 'when no keys are found' do
    let(:collection) { [] }

    it 'does not iterate over any elements' do
      results = subject.sscan_each(key).map do |k|
        k
      end
      expect(results).to match_array(collection)
    end
  end

  context 'when keys are found' do
    context 'when no match filter is supplied' do
      let(:collection) { Array.new(20) { |i| "k#{i}" } }

      it 'iterates over each item in the collection' do
        results = subject.sscan_each(key).map do |k|
          k
        end
        expect(results).to match_array(collection)
      end
    end

    context 'when giving a custom match filter' do
      let(:match) { 'k1*' }
      let(:collection) { Array.new(12) { |i| "k#{i}" } }
      let(:expected) { %w[k1 k10 k11] }

      it 'iterates over each item in the filtered collection' do
        results = subject.sscan_each(key, match: match).map do |k|
          k
        end
        expect(results).to match_array(expected)
      end
    end
  end
end
