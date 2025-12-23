require 'spec_helper'

describe WorkingHours::CoreExt::DateAndTime do
  let(:duration) { 5.working.days }

  describe 'operator +' do
    it 'works with Time objects' do
      time = Time.now
      expect(WorkingHours).to receive(:add_days).with(time, 5)
      time + duration
    end

    it 'works with Date objects' do
      date = Date.today
      expect(WorkingHours).to receive(:add_days).with(date, 5)
      date + duration
    end

    it 'works with DateTime objects' do
      date_time = DateTime.now
      expect(WorkingHours).to receive(:add_days).with(date_time, 5)
      date_time + duration
    end

    it 'works with ActiveSupport::TimeWithZone' do
      time = Time.now.in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:add_days).with(time, 5)
      time + duration
    end

    it "doesn't break original Time operator" do
      time = Time.now
      expect(WorkingHours).not_to receive(:add_days)
      expect(time + 3600).to eq(time + 1.hour)
    end

    it "doesn't break original Date operator" do
      date = Date.today
      expect(WorkingHours).not_to receive(:add_days)
      expect(date + 1).to eq(date + 1.day)
    end

    it "doesn't break original DateTime operator" do
      datetime = DateTime.now.change(usec: 0)
      expect(WorkingHours).not_to receive(:add_days)
      expect(datetime + 1).to eq(datetime + 1.day)
    end

    it "doesn't break original TimeWithZone operator" do
      Time.zone = 'UTC'
      time = Time.zone.now
      expect(WorkingHours).not_to receive(:add_days)
      expect(time + 1).to eq(time + 1.second)
    end
  end

  describe 'operator -' do
    it 'works with Time objects' do
      time = Time.now
      expect(WorkingHours).to receive(:add_days).with(time, -5)
      time - duration
    end

    it 'works with Date objects' do
      date = Date.today
      expect(WorkingHours).to receive(:add_days).with(date, -5)
      date - duration
    end

    it 'works with DateTime objects' do
      date_time = DateTime.now
      expect(WorkingHours).to receive(:add_days).with(date_time, -5)
      date_time - duration
    end

    it 'works with ActiveSupport::TimeWithZone' do
      time = Time.now.in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:add_days).with(time, -5)
      time - duration
    end

    it "doesn't break original Time operator" do
      time = Time.now
      expect(WorkingHours).not_to receive(:add_days)
      expect(time - 3600).to eq(time - 1.hour)
    end

    it "doesn't break original Date operator" do
      date = Date.today
      expect(WorkingHours).not_to receive(:add_days)
      expect(date - 1).to eq(date - 1.day)
    end

    it "doesn't break original DateTime operator" do
      datetime = DateTime.now.change(usec: 0)
      expect(WorkingHours).not_to receive(:add_days)
      expect(datetime - 1).to eq(datetime - 1.day)
    end

    it "doesn't break original TimeWithZone operator" do
      Time.zone = 'UTC'
      time = Time.zone.now
      expect(WorkingHours).not_to receive(:add_days)
      expect(time - 1).to eq(time - 1.second)
    end
  end

  describe '#working_days_until' do
    it 'works with Time objects' do
      from = Time.new(1991, 11, 15)
      to = Time.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_days_between).with(from, to)
      from.working_days_until(to)
    end

    it 'works with Date objects' do
      from = Date.new(1991, 11, 15)
      to = Date.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_days_between).with(from, to)
      from.working_days_until(to)
    end

    it 'works with DateTime objects' do
      from = DateTime.new(1991, 11, 15)
      to = DateTime.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_days_between).with(from, to)
      from.working_days_until(to)
    end

    it 'works with ActiveSupport::TimeWithZone' do
      from = Time.new(1991, 11, 15).in_time_zone('Tokyo')
      to = Time.new(1991, 11, 22).in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:working_days_between).with(from, to)
      from.working_days_until(to)
    end
  end

  describe '#working_time_until' do
    it 'works with Time objects' do
      from = Time.new(1991, 11, 15)
      to = Time.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_time_between).with(from, to)
      from.working_time_until(to)
    end

    it 'works with Date objects' do
      from = Date.new(1991, 11, 15)
      to = Date.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_time_between).with(from, to)
      from.working_time_until(to)
    end

    it 'works with DateTime objects' do
      from = DateTime.new(1991, 11, 15)
      to = DateTime.new(1991, 11, 22)
      expect(WorkingHours).to receive(:working_time_between).with(from, to)
      from.working_time_until(to)
    end

    it 'works with ActiveSupport::TimeWithZone' do
      from = Time.new(1991, 11, 15).in_time_zone('Tokyo')
      to = Time.new(1991, 11, 22).in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:working_time_between).with(from, to)
      from.working_time_until(to)
    end
  end

  describe '#working_day?' do
    it 'works with Time objects' do
      time = Time.new(1991, 11, 15)
      expect(WorkingHours).to receive(:working_day?).with(time)
      time.working_day?
    end

    it 'works with Date objects' do
      time = Date.new(1991, 11, 15)
      expect(WorkingHours).to receive(:working_day?).with(time)
      time.working_day?
    end

    it 'works with DateTime objects' do
      time = DateTime.new(1991, 11, 15)
      expect(WorkingHours).to receive(:working_day?).with(time)
      time.working_day?
    end

    it 'works with ActiveSupport::TimeWithZone' do
      time = Time.new(1991, 11, 15).in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:working_day?).with(time)
      time.working_day?
    end
  end

  describe '#in_working_hours?' do
    it 'works with Time objects' do
      time = Time.new(1991, 11, 15)
      expect(WorkingHours).to receive(:in_working_hours?).with(time)
      time.in_working_hours?
    end

    it 'works with Date objects' do
      time = Date.new(1991, 11, 15)
      expect(WorkingHours).to receive(:in_working_hours?).with(time)
      time.in_working_hours?
    end

    it 'works with DateTime objects' do
      time = DateTime.new(1991, 11, 15)
      expect(WorkingHours).to receive(:in_working_hours?).with(time)
      time.in_working_hours?
    end

    it 'works with ActiveSupport::TimeWithZone' do
      time = Time.new(1991, 11, 15).in_time_zone('Tokyo')
      expect(WorkingHours).to receive(:in_working_hours?).with(time)
      time.in_working_hours?
    end
  end
end
