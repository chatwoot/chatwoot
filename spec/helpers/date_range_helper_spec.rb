require 'rails_helper'

describe DateRangeHelper do
  let(:helper_class) do
    Class.new do
      include DateRangeHelper

      attr_reader :params

      def initialize(params)
        @params = params
      end
    end
  end

  def range_for(params)
    helper_class.new(ActionController::Parameters.new(params)).range
  end

  describe '#range' do
    let(:since_epoch) { 3.days.ago.beginning_of_day.to_i.to_s }
    let(:until_epoch) { 1.day.ago.end_of_day.to_i.to_s }

    it 'returns nil when neither bound is given' do
      expect(range_for({})).to be_nil
    end

    it 'builds the range from both bounds' do
      range = range_for(since: since_epoch, until: until_epoch)

      expect(range.first.to_i).to eq(since_epoch.to_i)
      expect(range.last.to_i).to eq(until_epoch.to_i)
      expect(range).to be_exclude_end
    end

    it 'defaults the upper bound to now when only since is given' do
      # Regression: a single bound used to return nil, which every caller
      # treats as "no filter" - a since-only request silently received the
      # full unfiltered history.
      range = range_for(since: since_epoch)

      expect(range).not_to be_nil
      expect(range.first.to_i).to eq(since_epoch.to_i)
      expect(range.last.to_i).to be_within(5).of(Time.zone.now.to_i)
    end

    it 'defaults the lower bound to the epoch when only until is given' do
      range = range_for(until: until_epoch)

      expect(range).not_to be_nil
      expect(range.first.to_i).to eq(0)
      expect(range.last.to_i).to eq(until_epoch.to_i)
    end

    it 'keeps both bounds concrete so callers may use range.first and range.last' do
      range = range_for(since: since_epoch)

      expect { range.first }.not_to raise_error
      expect { range.last }.not_to raise_error
    end
  end
end
