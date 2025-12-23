require 'spec_helper'

describe WorkingHours::Duration do

  describe '#initialize' do
    it 'is initialized with a number and a type' do
      duration = WorkingHours::Duration.new(5, :days)
      expect(duration.value).to eq(5)
      expect(duration.kind).to eq(:days)
    end

    it 'should work with days' do
      duration = WorkingHours::Duration.new(42, :days)
      expect(duration.kind).to eq(:days)
    end

    it 'should work with hours' do
      duration = WorkingHours::Duration.new(42, :hours)
      expect(duration.kind).to eq(:hours)
    end

    it 'should work with minutes' do
      duration = WorkingHours::Duration.new(42, :minutes)
      expect(duration.kind).to eq(:minutes)
    end

    it 'should work with seconds' do
      duration = WorkingHours::Duration.new(42, :seconds)
      expect(duration.kind).to eq(:seconds)
    end

    it 'should not work with anything else' do
      expect {
        duration = WorkingHours::Duration.new(42, :foo)
      }.to raise_error ArgumentError, "Invalid working time unit: foo"
    end
  end

  describe '#-@' do
    it 'inverses value' do
      expect(-2.working.days).to eq(WorkingHours::Duration.new(-2, :days))
      expect(-(-1.working.hour)).to eq(WorkingHours::Duration.new(1, :hours))
    end
  end

  describe '#since' do
    it "performs addition with Time.now" do
      Timecop.freeze(Time.utc(1991, 11, 15, 21)) # we are Friday 21 pm UTC
      expect(1.working.day.since).to eq(Time.utc(1991, 11, 18, 21))
    end

    it "is aliased to from_now" do
      Timecop.freeze(Time.utc(1991, 11, 15, 21)) # we are Friday 21 pm UTC
      expect(1.working.day.from_now).to eq(Time.utc(1991, 11, 18, 21))
    end

    it "accepts reference time as argument" do
      expect(1.working.day.since(Time.utc(1991, 11, 15, 21))).to eq(Time.utc(1991, 11, 18, 21))
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(7.working.days.from_now.zone).to eq('JST')
    end

    it 'should not hang with fractional hours' do
      WorkingHours::Duration.new(4.1, :hours).since(Time.utc(1991, 11, 15, 21))
    end
  end

  describe '#until' do
    it "performs substraction with Time.now" do
      Timecop.freeze(Time.utc(1991, 11, 15, 21)) # we are Friday 21 pm UTC
      expect(7.working.day.until).to eq(Time.utc(1991, 11, 6, 21))
    end

    it "is aliased to ago" do
      Timecop.freeze(Time.utc(1991, 11, 15, 21)) # we are Friday 21 pm UTC
      expect(7.working.day.ago).to eq(Time.utc(1991, 11, 6, 21))
    end

    it "accepts reference time as argument" do
      expect(7.working.day.until(Time.utc(1991, 11, 15, 21))).to eq(Time.utc(1991, 11, 6, 21))
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(7.working.days.ago.zone).to eq('JST')
    end
  end

end
