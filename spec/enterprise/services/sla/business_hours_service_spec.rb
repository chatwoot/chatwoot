require 'rails_helper'

RSpec.describe Sla::BusinessHoursService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account, working_hours_enabled: true, timezone: 'UTC') }

  # Default working hours: Mon-Fri 9:00-17:00 UTC, Sat-Sun closed
  describe '#deadline' do
    context 'when business hours should not apply' do
      it 'returns wall-clock deadline when working_hours_enabled is false' do
        inbox.update!(working_hours_enabled: false)
        start_time = Time.zone.parse('2024-01-19 16:00:00')

        service = described_class.new(inbox: inbox, start_time: start_time, threshold_seconds: 3600)

        expect(service.deadline.to_i).to eq((start_time + 1.hour).to_i)
      end

      it 'returns wall-clock deadline when all days are closed' do
        inbox.working_hours.find_each { |wh| wh.update!(closed_all_day: true) }
        start_time = Time.zone.parse('2024-01-19 16:00:00')

        service = described_class.new(inbox: inbox, start_time: start_time, threshold_seconds: 3600)

        expect(service.deadline.to_i).to eq((start_time + 1.hour).to_i)
      end
    end

    context 'when start time is during business hours' do
      it 'calculates deadline within the same day' do
        # Wednesday 10:00 AM + 2 hours = Wednesday 12:00 PM
        start_time = Time.zone.parse('2024-01-17 10:00:00') # Wednesday
        expected_deadline = Time.zone.parse('2024-01-17 12:00:00')

        service = described_class.new(inbox: inbox, start_time: start_time, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(expected_deadline.to_i)
      end

      it 'spans to next business day when threshold exceeds remaining hours' do
        # Friday 4:00 PM + 2 hours = Monday 10:00 AM (1h Friday + 1h Monday)
        friday_4pm = Time.zone.parse('2024-01-19 16:00:00')
        monday_10am = Time.zone.parse('2024-01-22 10:00:00')

        service = described_class.new(inbox: inbox, start_time: friday_4pm, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(monday_10am.to_i)
      end
    end

    context 'when start time is before business hours' do
      it 'starts counting from business hours open time' do
        # Wednesday 7:00 AM + 2 hours = Wednesday 11:00 AM (starts at 9 AM)
        start_time = Time.zone.parse('2024-01-17 07:00:00') # Wednesday 7 AM
        expected_deadline = Time.zone.parse('2024-01-17 11:00:00') # Wednesday 11 AM

        service = described_class.new(inbox: inbox, start_time: start_time, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(expected_deadline.to_i)
      end
    end

    context 'when start time is after business hours' do
      it 'starts counting from next business day' do
        # Wednesday 6:00 PM + 2 hours = Thursday 11:00 AM
        start_time = Time.zone.parse('2024-01-17 18:00:00') # Wednesday 6 PM
        expected_deadline = Time.zone.parse('2024-01-18 11:00:00') # Thursday 11 AM

        service = described_class.new(inbox: inbox, start_time: start_time, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(expected_deadline.to_i)
      end
    end

    context 'when start time is on a closed day' do
      it 'starts counting from next business day' do
        # Saturday 10:00 AM + 2 hours = Monday 11:00 AM
        saturday = Time.zone.parse('2024-01-20 10:00:00')
        monday_11am = Time.zone.parse('2024-01-22 11:00:00')

        service = described_class.new(inbox: inbox, start_time: saturday, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(monday_11am.to_i)
      end
    end

    context 'when threshold spans multiple days' do
      it 'calculates correctly across multiple business days' do
        # Monday 4:00 PM + 10 hours = Wednesday 10:00 AM
        # Monday: 1h (4-5 PM), Tuesday: 8h (9-5), Wednesday: 1h (9-10 AM)
        monday_4pm = Time.zone.parse('2024-01-15 16:00:00')
        wednesday_10am = Time.zone.parse('2024-01-17 10:00:00')

        service = described_class.new(inbox: inbox, start_time: monday_4pm, threshold_seconds: 10.hours)

        expect(service.deadline.to_i).to eq(wednesday_10am.to_i)
      end
    end

    context 'with different timezone' do
      it 'respects inbox timezone' do
        inbox.update!(timezone: 'America/New_York')
        # Friday 4:00 PM EST + 2 hours = Monday 10:00 AM EST
        friday_4pm_est = Time.zone.parse('2024-01-19 16:00:00 EST')
        monday_10am_est = Time.zone.parse('2024-01-22 10:00:00 EST')

        service = described_class.new(inbox: inbox, start_time: friday_4pm_est, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(monday_10am_est.to_i)
      end
    end

    context 'when day is open all day' do
      it 'treats the day as 24 hours of business time' do
        # Set Saturday to open_all_day (0:00 - 23:59)
        inbox.working_hours.find_by(day_of_week: 6).update!(open_all_day: true, closed_all_day: false)

        # Saturday 10:00 AM + 2 hours = Saturday 12:00 PM
        saturday_10am = Time.zone.parse('2024-01-20 10:00:00')
        saturday_12pm = Time.zone.parse('2024-01-20 12:00:00')

        service = described_class.new(inbox: inbox, start_time: saturday_10am, threshold_seconds: 2.hours)

        expect(service.deadline.to_i).to eq(saturday_12pm.to_i)
      end
    end
  end
end
