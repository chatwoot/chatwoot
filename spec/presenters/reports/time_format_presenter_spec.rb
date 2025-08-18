require 'rails_helper'

RSpec.describe Reports::TimeFormatPresenter do
  describe '#format' do
    context 'when formatting days' do
      it 'formats single day correctly' do
        expect(described_class.new(86_400).format).to eq '1 day'
      end

      it 'formats multiple days correctly' do
        expect(described_class.new(172_800).format).to eq '2 days'
      end

      it 'includes seconds with days correctly' do
        expect(described_class.new(86_401).format).to eq '1 day 1 second'
      end

      it 'includes hours with days correctly' do
        expect(described_class.new(93_600).format).to eq '1 day 2 hours'
      end

      it 'includes minutes with days correctly' do
        expect(described_class.new(86_461).format).to eq '1 day 1 minute'
      end
    end

    context 'when formatting hours' do
      it 'formats single hour correctly' do
        expect(described_class.new(3600).format).to eq '1 hour'
      end

      it 'formats multiple hours correctly' do
        expect(described_class.new(7200).format).to eq '2 hours'
      end

      it 'includes seconds with hours correctly' do
        expect(described_class.new(3601).format).to eq '1 hour 1 second'
      end

      it 'includes minutes with hours correctly' do
        expect(described_class.new(3660).format).to eq '1 hour 1 minute'
      end
    end

    context 'when formatting minutes' do
      it 'formats single minute correctly' do
        expect(described_class.new(60).format).to eq '1 minute'
      end

      it 'formats multiple minutes correctly' do
        expect(described_class.new(120).format).to eq '2 minutes'
      end

      it 'includes seconds with minutes correctly' do
        expect(described_class.new(62).format).to eq '1 minute 2 seconds'
      end
    end

    context 'when formatting seconds' do
      it 'formats multiple seconds correctly' do
        expect(described_class.new(56).format).to eq '56 seconds'
      end

      it 'handles floating-point seconds by truncating to the nearest lower second' do
        expect(described_class.new(55.2).format).to eq '55 seconds'
      end

      it 'formats single second correctly' do
        expect(described_class.new(1).format).to eq '1 second'
      end

      it 'formats nil second correctly' do
        expect(described_class.new.format).to eq 'N/A'
      end
    end
  end
end
