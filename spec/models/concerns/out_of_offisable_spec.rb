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
end
