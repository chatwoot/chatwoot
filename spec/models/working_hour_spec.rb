# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkingHour do
  context 'when on monday 10am' do
    before do
      Time.zone = 'UTC'
      create(:working_hour)
      travel_to '26.10.2020 10:00'.to_datetime
    end

    it 'is considered working hour' do
      expect(described_class.today.open_now?).to be true
    end
  end

  context 'when on sunday 1pm' do
    before do
      Time.zone = 'UTC'
      create(:working_hour, day_of_week: 0, closed_all_day: true)
      travel_to '01.11.2020 13:00'.to_datetime
    end

    it 'is considered out of office' do
      expect(described_class.today.closed_now?).to be true
    end
  end
end
