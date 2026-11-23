require 'rails_helper'

shared_examples_for 'out_of_offisable' do
  let(:obj) { create(described_class.to_s.underscore, working_hours_enabled: true, out_of_office_message: 'Message') }

  it 'has after create callback' do
    expect(obj.working_hours.count).to eq(7)
  end

  it 'is working on monday 10am' do
    travel_to '26.10.2020 10:00'.to_datetime
    expect(obj.working_now?).to be true
  end

  it 'is out of office on sunday 1pm' do
    travel_to '01.11.2020 13:00'.to_datetime
    expect(obj.out_of_office?).to be true
  end

  it 'updates the office hours via a hash' do
    obj.update_working_hours([{ 'day_of_week' => 1, 'open_hour' => 10, 'open_minutes' => 0,
                                'close_hour' => 17, 'close_minutes' => 0 }])
    expect(obj.reload.weekly_schedule.find { |schedule| schedule['day_of_week'] == 1 }['open_hour']).to eq 10
  end

  describe '#next_working_time' do
    # Default working hours: Mon-Fri 9:00-17:00, weekends closed.
    before { obj.update!(timezone: 'Asia/Kolkata') }

    let(:zone) { ActiveSupport::TimeZone['Asia/Kolkata'] }

    it 'returns the same time while the inbox is open' do
      time = zone.parse('2024-01-22 10:00')
      expect(obj.next_working_time(time)).to eq(time)
    end

    it 'moves a time after Friday closing to Monday opening, in the inbox timezone' do
      expect(obj.next_working_time(zone.parse('2024-01-19 17:00'))).to eq(zone.parse('2024-01-22 09:00'))
    end

    it 'returns the same time when working hours are disabled' do
      obj.update!(working_hours_enabled: false)
      time = zone.parse('2024-01-20 12:00')
      expect(obj.next_working_time(time)).to eq(time)
    end
  end
end
