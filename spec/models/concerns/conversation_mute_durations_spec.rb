require 'rails_helper'

RSpec.describe ConversationMuteDurations do
  describe '.resolve' do
    it 'returns the time for a preset' do
      freeze_time do
        expect(described_class.resolve('8_hours')).to eq(8.hours.from_now)
      end
    end

    it 'returns nil for unknown values' do
      expect(described_class.resolve('permanent')).to be_nil
      expect(described_class.resolve(nil)).to be_nil
      expect(described_class.resolve('')).to be_nil
    end
  end

  describe '.parse' do
    it 'accepts presets' do
      freeze_time do
        expect(described_class.parse('1_day')).to eq(1.day.from_now)
      end
    end

    it 'accepts a future ISO8601 timestamp' do
      time = 2.days.from_now.change(usec: 0)
      expect(described_class.parse(time.iso8601)).to eq(time)
    end

    it 'returns nil for past timestamps' do
      expect(described_class.parse(1.day.ago.iso8601)).to be_nil
    end

    it 'returns nil for blank or unparsable values' do
      expect(described_class.parse(nil)).to be_nil
      expect(described_class.parse('')).to be_nil
      expect(described_class.parse('not-a-time')).to be_nil
    end
  end
end
