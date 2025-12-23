require 'spec_helper'

describe WorkingHours do

  it 'can be used to call computation methods' do
    [ :advance_to_working_time, :return_to_working_time,
      :working_day?, :in_working_hours?,
      :working_days_between, :working_time_between
    ].each do |method|
      expect(WorkingHours).to respond_to(method)
    end
  end

end