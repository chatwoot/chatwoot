require 'spec_helper'

describe WorkingHours::Computation do
  include WorkingHours::Computation

  describe '#add_days' do
    it 'can add working days to date' do
      date = Date.new(1991, 11, 15) #Friday
      expect(add_days(date, 2)).to eq(Date.new(1991, 11, 19)) # Tuesday
    end

    it 'can substract working days from date' do
      date = Date.new(1991, 11, 15) #Friday
      expect(add_days(date, -7)).to eq(Date.new(1991, 11, 6)) # Wednesday
    end

    it 'can add working days to time' do
      time = Time.local(1991, 11, 15, 14, 00, 42)
      expect(add_days(time, 1)).to eq(Time.local(1991, 11, 18, 14, 00, 42)) # Monday
    end

    it 'can add working days to ActiveSupport::TimeWithZone' do
      time = Time.utc(1991, 11, 15, 14, 00, 42)
      time_monday = Time.utc(1991, 11, 18, 14, 00, 42)
      time_with_zone = ActiveSupport::TimeWithZone.new(time, 'Tokyo')
      expect(add_days(time_with_zone, 1)).to eq(ActiveSupport::TimeWithZone.new(time_monday, 'Tokyo'))
    end

    it 'skips non worked days' do
      time = Date.new(2014, 4, 7) # Monday
      WorkingHours::Config.working_hours = {mon: {'09:00' => '17:00'}, wed: {'09:00' => '17:00'}}
      expect(add_days(time, 1)).to eq(Date.new(2014, 4, 9)) # Wednesday
    end

    it 'skips non worked days when origin is not worked' do
      time = Date.new(2014, 4, 8) # Tuesday
      WorkingHours::Config.working_hours = {mon: {'09:00' => '17:00'}, wed: {'09:00' => '17:00'}, thu: {'09:00' => '17:00'}, sun: {'09:00' => '17:00'}}
      expect(add_days(time, 1)).to eq(Date.new(2014, 4, 10)) # Thursday
      expect(add_days(time, -1)).to eq(Date.new(2014, 4, 6)) # Sunday
    end

    it 'skips holidays' do
      time = Date.new(2014, 4, 7) # Monday
      WorkingHours::Config.holidays = [Date.new(2014, 4, 8)] # Tuesday
      expect(add_days(time, 1)).to eq(Date.new(2014, 4, 9)) # Wednesday
    end

    it 'skips holidays when origin is holiday' do
      time = Date.new(2014, 4, 9) # Wednesday
      WorkingHours::Config.holidays = [time] # Wednesday
      expect(add_days(time, 1)).to eq(Date.new(2014, 4, 11)) # Friday
      expect(add_days(time, -1)).to eq(Date.new(2014, 4, 7)) # Monday
    end

    it 'skips holidays and non worked days' do
      time = Date.new(2014, 4, 7) # Monday
      WorkingHours::Config.holidays = [Date.new(2014, 4, 9)] # Wednesday
      WorkingHours::Config.working_hours = {mon: {'09:00' => '17:00'}, wed: {'09:00' => '17:00'}}
      expect(add_days(time, 3)).to eq(Date.new(2014, 4, 21))
    end

    it 'returns the original value when adding 0 days' do
      time = Date.new(2014, 4, 7)
      WorkingHours::Config.holidays = [time]
      expect(add_days(time, 0)).to eq(time)
    end

    it 'accepts time given from any time zone' do
      time = Time.utc(1991, 11, 14, 21, 0, 0) # Thursday 21 pm UTC
      WorkingHours::Config.time_zone = 'Tokyo' # But we are at tokyo, so it's already Friday 6 am
      monday = Time.new(1991, 11, 18, 6, 0, 0, "+09:00") # so one working day later, we are monday (Tokyo)
      expect(add_days(time, 1)).to eq(monday)
    end
  end

  describe '#add_hours' do
    it 'adds working hours' do
      time = Time.utc(1991, 11, 15, 14, 00, 42) # Friday
      expect(add_hours(time, 2)).to eq(Time.utc(1991, 11, 15, 16, 00, 42))
    end

    it 'can substract working hours' do
      time = Time.utc(1991, 11, 18, 14, 00, 42) # Monday
      expect(add_hours(time, -7)).to eq(Time.utc(1991, 11, 15, 15, 00, 42)) # Friday
    end

    it 'accepts time given from any time zone' do
      time = Time.utc(1991, 11, 15, 7, 0, 0) # Friday 7 am UTC
      WorkingHours::Config.time_zone = 'Tokyo' # But we are at tokyo, so it's already 4 pm
      monday = Time.new(1991, 11, 18, 11, 0, 0, "+09:00") # so 3 working hours later, we are monday (Tokyo)
      expect(add_hours(time, 3)).to eq(monday)
    end

    it 'moves correctly with multiple timespans' do
      WorkingHours::Config.working_hours = {mon: {'07:00' => '12:00', '13:00' => '18:00'}}
      time = Time.utc(1991, 11, 11, 5) # Monday 6 am UTC
      expect(add_hours(time, 6)).to eq(Time.utc(1991, 11, 11, 14))
    end
  end

  describe '#add_minutes' do
    it 'adds working minutes' do
      time = Time.utc(1991, 11, 15, 16, 30, 42) # Friday
      expect(add_minutes(time, 45)).to eq(Time.utc(1991, 11, 18, 9, 15, 42))
    end
  end

  describe '#add_seconds' do
    it 'adds working seconds' do
      time = Time.utc(1991, 11, 15, 16, 59, 42) # Friday
      expect(add_seconds(time, 120)).to eq(Time.utc(1991, 11, 18, 9, 1, 42))
    end

    it 'calls precompiled only once' do
      precompiled = WorkingHours::Config.precompiled
      expect(WorkingHours::Config).to receive(:precompiled).once.and_return(precompiled) # in_config_zone and add_seconds
      time = Time.utc(1991, 11, 15, 16, 59, 42) # Friday
      add_seconds(time, 120)
    end

    it 'supports midnight when advancing time' do
      WorkingHours::Config.working_hours = {:mon => {'00:00' => '24:00'}}
      time = Time.utc(2014, 4, 7, 23, 59, 30) # Monday
      expect(add_seconds(time, 60)).to eq(Time.utc(2014, 4, 14, 0, 0, 30))
    end

    it 'supports midnight when rewinding time' do
      WorkingHours::Config.working_hours = {:mon => {'00:00' => '24:00'}, :tue => {'08:00' => '18:00'}}
      time = Time.utc(2014, 4, 8, 0, 0, 30) # Tuesday
      expect(add_seconds(time, -60)).to eq(Time.utc(2014, 4, 7, 23, 59, 00))
    end

    context 'with holiday hours' do
      before do
        WorkingHours::Config.working_hours = { thu: { '08:00' => '18:00' }, fri: { '08:00' => '18:00' } }
      end

      context 'with a later starting hour' do
        before do
          WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '10:00' => '18:00' } }
        end

        it 'adds working seconds' do
          time = Time.utc(2019, 12, 27, 9)
          expect(add_seconds(time, 120)).to eq(Time.utc(2019, 12, 27, 10, 2))
        end

        it 'removes working seconds' do
          time = Time.utc(2019, 12, 27, 9)
          expect(add_seconds(time, -120)).to eq(Time.utc(2019, 12, 26, 17, 58))
        end

        context 'working back from working hours' do
          it 'moves to the previous working day' do
            time = Time.utc(2019, 12, 27, 11)
            expect(add_seconds(time, -2.hours)).to eq(Time.utc(2019, 12, 26, 17))
          end
        end
      end

      context 'with an earlier ending hour' do
        before do
          WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '08:00' => '17:00' } }
        end

        it 'adds working seconds' do
          time = Time.utc(2019, 12, 27, 17, 59)
          expect(add_seconds(time, 120)).to eq(Time.utc(2020, 1, 2, 8, 2))
        end

        it 'removes working seconds' do
          time = Time.utc(2019, 12, 27, 18)
          expect(add_seconds(time, -120)).to eq(Time.utc(2019, 12, 27, 16, 58))
        end

        context 'working forward from working hours' do
          it 'moves to the next working day' do
            time = Time.utc(2019, 12, 27, 16)
            expect(add_seconds(time, 2.hours)).to eq(Time.utc(2020, 1, 2, 9))
          end
        end
      end

      context 'with an earlier starting time in the second set of hours within a day' do
        before do
          WorkingHours::Config.working_hours = { thu: { '08:00' => '18:00' }, fri: { '08:00' => '12:00', '13:00' => '18:00' } }
          WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '08:00' => '12:00', '14:00' => '18:00' } }
        end

        it 'adds working seconds' do
          time = Time.utc(2019, 12, 27, 12, 59)
          expect(add_seconds(time, 120)).to eq(Time.utc(2019, 12, 27, 14, 2))
        end

        it 'removes working seconds' do
          time = Time.utc(2019, 12, 27, 14)
          expect(add_seconds(time, -120)).to eq(Time.utc(2019, 12, 27, 11, 58))
        end

        context 'from morning to afternoon' do
          it 'takes into account the additional hour for lunch set in `holiday_hours`' do
            time = Time.utc(2019, 12, 27, 10)
            expect(add_seconds(time, 4.hours)).to eq(Time.utc(2019, 12, 27, 16))
          end
        end

        context 'from afternoon to morning' do
          it 'takes into account the additional hour for lunch set in `holiday_hours`' do
            time = Time.utc(2019, 12, 27, 16)
            expect(add_seconds(time, -4.hours)).to eq(Time.utc(2019, 12, 27, 10))
          end
        end
      end
    end

    it 'honors miliseconds in the base time and increment (but return rounded result)' do
      # Rounding the base time or increments before the end would yield a wrong result
      time = Time.utc(1991, 11, 15, 16, 59, 42.25) # +250ms
      expect(add_seconds(time, 120.4)).to eq(Time.utc(1991, 11, 18, 9, 1, 43))
    end
  end

  describe '#advance_to_working_time' do
    it 'jumps non-working day' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      expect(advance_to_working_time(Time.utc(2014, 5, 1, 12, 0))).to eq(Time.utc(2014, 5, 2, 9, 0))
      expect(advance_to_working_time(Time.utc(2014, 6, 1, 12, 0))).to eq(Time.utc(2014, 6, 2, 9, 0))
    end

    it 'returns self during working hours' do
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 9, 0))).to eq(Time.utc(2014, 4, 7, 9, 0))
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 16, 59))).to eq(Time.utc(2014, 4, 7, 16, 59))
    end

    it 'jumps outside working hours' do
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 8, 59))).to eq(Time.utc(2014, 4, 7, 9, 0))
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 17, 0))).to eq(Time.utc(2014, 4, 8, 9, 0))
    end

    it 'move between timespans' do
      WorkingHours::Config.working_hours = {mon: {'07:00' => '12:00', '13:00' => '18:00'}}
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 11, 59))).to eq(Time.utc(2014, 4, 7, 11, 59))
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 12, 0))).to eq(Time.utc(2014, 4, 7, 13, 0))
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 12, 59))).to eq(Time.utc(2014, 4, 7, 13, 0))
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 13, 0))).to eq(Time.utc(2014, 4, 7, 13, 0))
    end

    it 'works with any input timezone (converts to config)' do
      # Monday 0 am (-09:00) is 9am in UTC time, working time!
      expect(advance_to_working_time(Time.new(2014, 4, 7, 0, 0, 0 , "-09:00"))).to eq(Time.utc(2014, 4, 7, 9))
      expect(advance_to_working_time(Time.new(2014, 4, 7, 22, 0, 0 , "+02:00"))).to eq(Time.utc(2014, 4, 8, 9))
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(advance_to_working_time(Time.new(2014, 4, 7, 0, 0, 0)).zone).to eq('JST')
    end

    it 'jumps outside holiday hours' do
      WorkingHours::Config.working_hours = { fri: { '08:00' => '18:00' } }
      WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '10:00' => '18:00' } }
      expect(advance_to_working_time(Time.utc(2019, 12, 27, 9))).to eq(Time.utc(2019, 12, 27, 10))
    end

    it 'do not leak nanoseconds when advancing' do
      expect(advance_to_working_time(Time.utc(2014, 4, 7, 5, 0, 0, 123456.789))).to eq(Time.utc(2014, 4, 7, 9, 0, 0, 0))
    end

    it 'returns correct hour during positive time shifts' do
      WorkingHours::Config.working_hours = {sun: {'09:00' => '17:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 3, 29, 0, 0, 0, "+01:00")
      expect(from.utc_offset).to eq(3600)
      res = advance_to_working_time(from)
      expect(res).to eq(Time.new(2020, 3, 29, 9, 0, 0, "+02:00"))
      expect(res.utc_offset).to eq(7200)
      # starting from wrong time-zone
      expect(advance_to_working_time(Time.new(2020, 3, 29, 5, 0, 0, "+01:00"))).to eq(Time.new(2020, 3, 29, 9, 0, 0, "+02:00"))
      expect(advance_to_working_time(Time.new(2020, 3, 29, 1, 0, 0, "+02:00"))).to eq(Time.new(2020, 3, 29, 9, 0, 0, "+02:00"))
    end

    it 'returns correct hour during negative time shifts' do
      WorkingHours::Config.working_hours = {sun: {'09:00' => '17:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 10, 25, 0, 0, 0, "+02:00")
      expect(from.utc_offset).to eq(7200)
      res = advance_to_working_time(from)
      expect(res).to eq(Time.new(2020, 10, 25, 9, 0, 0, "+01:00"))
      expect(res.utc_offset).to eq(3600)
      # starting from wrong time-zone
      expect(advance_to_working_time(Time.new(2020, 10, 25, 4, 0, 0, "+02:00"))).to eq(Time.new(2020, 10, 25, 9, 0, 0, "+01:00"))
      expect(advance_to_working_time(Time.new(2020, 10, 25, 1, 0, 0, "+01:00"))).to eq(Time.new(2020, 10, 25, 9, 0, 0, "+01:00"))
    end
  end

  describe '#advance_to_closing_time' do
    it 'jumps non-working day' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      holiday = Time.utc(2014, 5, 1, 12, 0)
      friday_closing = Time.utc(2014, 5, 2, 17, 0)
      sunday = Time.utc(2014, 6, 1, 12, 0)
      monday_closing = Time.utc(2014, 6, 2, 17, 0)
      expect(advance_to_closing_time(holiday)).to eq(friday_closing)
      expect(advance_to_closing_time(sunday)).to eq(monday_closing)
    end

    it 'moves to the closing time during working hours' do
      in_open_time = Time.utc(2014, 4, 7, 12, 0)
      closing_time = Time.utc(2014, 4, 7, 17, 0)
      expect(advance_to_closing_time(in_open_time)).to eq(closing_time)
    end

    it 'jumps outside working hours' do
      monday_before_opening = Time.utc(2014, 4, 7, 8, 59)
      monday_closing = Time.utc(2014, 4, 7, 17, 0)
      tuesday_closing = Time.utc(2014, 4, 8, 17, 0)
      expect(advance_to_closing_time(monday_before_opening)).to eq(monday_closing)
      expect(advance_to_closing_time(monday_closing)).to eq(tuesday_closing)
    end

    context 'moving between timespans' do
      before do
        WorkingHours::Config.working_hours = {
          mon: {'07:00' => '12:00', '13:00' => '18:00'},
          tue: {'09:00' => '17:00'},
          wed: {'09:00' => '17:00'},
          thu: {'09:00' => '17:00'},
          fri: {'09:00' => '17:00'}
        }
      end

      let(:monday_morning) { Time.utc(2014, 4, 7, 10) }
      let(:morning_closing) { Time.utc(2014, 4, 7, 12) }
      let(:afternoon_closing) { Time.utc(2014, 4, 7, 18) }
      let(:monday_break) { Time.utc(2014, 4, 7, 12) }
      let(:tuesday_closing) { Time.utc(2014, 4, 8, 17) }

      it 'moves from morning to end of morning slot' do
        expect(advance_to_closing_time(monday_morning)).to eq(morning_closing)
      end

      it 'moves from break time to end of afternoon slot' do
        expect(advance_to_closing_time(monday_break)).to eq(afternoon_closing)
      end

      it 'moves from afternoon closing slot to next day' do
        expect(advance_to_closing_time(afternoon_closing)).to eq(tuesday_closing)
      end
    end

    context 'supporting midnight' do
      before do
        WorkingHours::Config.working_hours = {
          mon: {'00:00' => '24:00'},
          tue: {'09:00' => '17:00'}
        }
      end

      let(:monday_morning) { Time.utc(2014, 4, 7, 0) }
      let(:monday_closing) { Time.utc(2014, 4, 7) + WorkingHours::Config::MIDNIGHT }
      let(:tuesday_closing) { Time.utc(2014, 4, 8, 17) }
      let(:sunday) { Time.utc(2014, 4, 6, 17) }

      it 'moves from morning to midnight' do
        expect(advance_to_closing_time(monday_morning)).to eq(monday_closing)
      end

      it 'moves from midnight to end of next slot' do
        expect(advance_to_closing_time(monday_closing)).to eq(tuesday_closing)
      end

      it 'moves over midnight' do
        expect(advance_to_closing_time(sunday)).to eq(monday_closing)
      end

      it 'give precise computation with nothing other than miliseconds' do
        pending "iso8601 is not precise enough on AS < 4" if ActiveSupport::VERSION::MAJOR <= 4
        expect(advance_to_closing_time(monday_morning).iso8601(25)).to eq("2014-04-07T23:59:59.9999990000000000000000000Z")
      end
    end

    it 'works with any input timezone (converts to config)' do
      # Monday 0 am (-09:00) is 9am in UTC time, working time!
      monday_morning = Time.new(2014, 4, 7, 0, 0, 0 , "-09:00")
      monday_closing = Time.new(2014, 4, 7, 12, 0, 0 , "-05:00")
      monday_night = Time.new(2014, 4, 7, 22, 0, 0, "+02:00")
      tuesday_evening = Time.utc(2014, 4, 8, 17)
      expect(advance_to_closing_time(monday_morning)).to eq(monday_closing)
      expect(advance_to_closing_time(monday_night)).to eq(tuesday_evening)
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(advance_to_closing_time(Time.new(2014, 4, 7, 0, 0, 0)).zone).to eq('JST')
    end

    context 'with holiday hours' do
      before do
        WorkingHours::Config.working_hours = { thu: { '08:00' => '18:00' }, fri: { '08:00' => '18:00' } }
      end

      it 'takes into account reduced holiday closing' do
        WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '10:00' => '17:00' } }
        expect(advance_to_closing_time(Time.new(2019, 12, 26, 20))).to eq(Time.new(2019, 12, 27, 17))
      end

      it 'takes into account extended holiday closing' do
        WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 26) => { '10:00' => '21:00' } }
        expect(advance_to_closing_time(Time.new(2019, 12, 26, 20))).to eq(Time.new(2019, 12, 26, 21))
      end
    end

    it 'do not leak nanoseconds when advancing' do
      expect(advance_to_closing_time(Time.utc(2014, 4, 7, 5, 0, 0, 123456.789))).to eq(Time.utc(2014, 4, 7, 17, 0, 0, 0))
    end

    it 'returns correct hour during positive time shifts' do
      WorkingHours::Config.working_hours = {sun: {'09:00' => '17:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 3, 29, 0, 0, 0, "+01:00")
      expect(from.utc_offset).to eq(3600)
      res = advance_to_closing_time(from)
      expect(res).to eq(Time.new(2020, 3, 29, 17, 0, 0, "+02:00"))
      expect(res.utc_offset).to eq(7200)
      # starting from wrong time-zone
      expect(advance_to_closing_time(Time.new(2020, 3, 29, 5, 0, 0, "+01:00"))).to eq(Time.new(2020, 3, 29, 17, 0, 0, "+02:00"))
      expect(advance_to_closing_time(Time.new(2020, 3, 29, 1, 0, 0, "+02:00"))).to eq(Time.new(2020, 3, 29, 17, 0, 0, "+02:00"))
    end

    it 'returns correct hour during negative time shifts' do
      WorkingHours::Config.working_hours = {sun: {'09:00' => '17:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 10, 25, 0, 0, 0, "+02:00")
      expect(from.utc_offset).to eq(7200)
      res = advance_to_closing_time(from)
      expect(res).to eq(Time.new(2020, 10, 25, 17, 0, 0, "+01:00"))
      expect(res.utc_offset).to eq(3600)
      # starting from wrong time-zone
      expect(advance_to_closing_time(Time.new(2020, 10, 25, 4, 0, 0, "+02:00"))).to eq(Time.new(2020, 10, 25, 17, 0, 0, "+01:00"))
      expect(advance_to_closing_time(Time.new(2020, 10, 25, 1, 0, 0, "+01:00"))).to eq(Time.new(2020, 10, 25, 17, 0, 0, "+01:00"))
    end
  end

  describe '#next_working_time' do
    it 'jumps non-working day' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      holiday = Time.utc(2014, 5, 1, 12, 0)
      sunday = Time.utc(2014, 6, 1, 12, 0)
      expect(next_working_time(holiday)).to eq(Time.utc(2014, 5, 2, 9, 0))
      expect(next_working_time(sunday)).to eq(Time.utc(2014, 6, 2, 9, 0))
    end

    it 'moves to the following timespan during working hours' do
      monday = Time.utc(2014, 4, 7, 12, 0)
      tuesday = Time.utc(2014, 4, 8, 9, 0)
      expect(next_working_time(monday)).to eq(tuesday)
    end

    it 'jumps outside working hours' do
      monday_before_opening = Time.utc(2014, 4, 7, 8, 59)
      monday_opening = Time.utc(2014, 4, 7, 9, 0)
      monday_closing = Time.utc(2014, 4, 7, 17, 0)
      tuesday_opening = Time.utc(2014, 4, 8, 9, 0)
      expect(next_working_time(monday_before_opening)).to eq(monday_opening)
      expect(next_working_time(monday_closing)).to eq(tuesday_opening)
    end

    context 'move between timespans' do
      before do
        WorkingHours::Config.working_hours = {
          mon: {'07:00' => '12:00', '13:00' => '18:00'},
          tue: {'09:00' => '17:00'},
          wed: {'09:00' => '17:00'},
          thu: {'09:00' => '17:00'},
          fri: {'09:00' => '17:00'}
        }
      end

      let(:monday_morning) { Time.utc(2014, 4, 7, 10) }
      let(:monday_afternoon) { Time.utc(2014, 4, 7, 13) }
      let(:monday_break) { Time.utc(2014, 4, 7, 12) }
      let(:tuesday_morning) { Time.utc(2014, 4, 8, 9) }

      it 'moves from morning to afternoon slot' do
        expect(next_working_time(monday_morning)).to eq(monday_afternoon)
      end

      it 'moves from break time to afternoon slot' do
        expect(next_working_time(monday_break)).to eq(monday_afternoon)
      end

      it 'moves from afternoon slot to next day' do
        expect(next_working_time(monday_afternoon)).to eq(tuesday_morning)
      end
    end

    it 'works with any input timezone (converts to config)' do
      # Monday 0 am (-09:00) is 9am in UTC time, working time!
      monday_morning = Time.new(2014, 4, 7, 0, 0, 0 , "-09:00")
      monday_night = Time.new(2014, 4, 7, 22, 0, 0, "+02:00")
      tuesday_morning = Time.utc(2014, 4, 8, 9)
      expect(next_working_time(monday_morning)).to eq(tuesday_morning)
      expect(next_working_time(monday_night)).to eq(tuesday_morning)
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(next_working_time(Time.new(2014, 4, 7, 0, 0, 0)).zone).to eq('JST')
    end
  end

  describe '#return_to_working_time' do
    it 'jumps non-working day' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      expect(return_to_working_time(Time.utc(2014, 5, 1, 12, 0))).to eq(Time.utc(2014, 4, 30, 17))
      expect(return_to_working_time(Time.utc(2014, 6, 1, 12, 0))).to eq(Time.utc(2014, 5, 30, 17))
    end

    it 'returns self during working hours' do
      expect(return_to_working_time(Time.utc(2014, 4, 7, 9, 1))).to eq(Time.utc(2014, 4, 7, 9, 1))
      expect(return_to_working_time(Time.utc(2014, 4, 7, 17, 0))).to eq(Time.utc(2014, 4, 7, 17, 0))
    end

    it 'jumps outside working hours' do
      expect(return_to_working_time(Time.utc(2014, 4, 7, 17, 1))).to eq(Time.utc(2014, 4, 7, 17, 0))
      expect(return_to_working_time(Time.utc(2014, 4, 8, 9, 0))).to eq(Time.utc(2014, 4, 7, 17, 0))
    end

    it 'move between timespans' do
      WorkingHours::Config.working_hours = {mon: {'07:00' => '12:00', '13:00' => '18:00'}}
      expect(return_to_working_time(Time.utc(2014, 4, 7, 13, 1))).to eq(Time.utc(2014, 4, 7, 13, 1))
      expect(return_to_working_time(Time.utc(2014, 4, 7, 13, 0))).to eq(Time.utc(2014, 4, 7, 12, 0))
      expect(return_to_working_time(Time.utc(2014, 4, 7, 12, 1))).to eq(Time.utc(2014, 4, 7, 12, 0))
      expect(return_to_working_time(Time.utc(2014, 4, 7, 12, 0))).to eq(Time.utc(2014, 4, 7, 12, 0))
    end

    it 'works with any input timezone (converts to config)' do
      # Monday 1 am (-09:00) is 10am in UTC time, working time!
      expect(return_to_working_time(Time.new(2014, 4, 7, 1, 0, 0 , "-09:00"))).to eq(Time.utc(2014, 4, 7, 10))
      expect(return_to_working_time(Time.new(2014, 4, 7, 22, 0, 0 , "+02:00"))).to eq(Time.utc(2014, 4, 7, 17))
    end

    it 'returns time in config zone' do
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(return_to_working_time(Time.new(2014, 4, 7, 1, 0, 0)).zone).to eq('JST')
    end

    it 'returns correct hour during positive time shifts' do
      WorkingHours::Config.working_hours = {sun: {'00:00' => '01:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 3, 29, 9, 0, 0, "+02:00")
      expect(from.utc_offset).to eq(7200)
      res = return_to_working_time(from)
      expect(res).to eq(Time.new(2020, 3, 29, 1, 0, 0, "+01:00"))
      expect(res.utc_offset).to eq(3600)
      # starting from wrong time-zone
      expect(return_to_working_time(Time.new(2020, 3, 29, 2, 0, 0, "+02:00"))).to eq(Time.new(2020, 3, 29, 1, 0, 0, "+01:00"))
      expect(return_to_working_time(Time.new(2020, 3, 29, 9, 0, 0, "+01:00"))).to eq(Time.new(2020, 3, 29, 1, 0, 0, "+01:00"))
    end

    it 'returns correct hour during negative time shifts' do
      WorkingHours::Config.working_hours = {sun: {'00:00' => '01:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      from = Time.new(2020, 10, 25, 9, 0, 0, "+01:00")
      expect(from.utc_offset).to eq(3600)
      res = return_to_working_time(from)
      expect(res).to eq(Time.new(2020, 10, 25, 1, 0, 0, "+02:00"))
      expect(res.utc_offset).to eq(7200)
      # starting from wrong time-zone
      expect(return_to_working_time(Time.new(2020, 10, 25, 9, 0, 0, "+02:00"))).to eq(Time.new(2020, 10, 25, 1, 0, 0, "+02:00"))
      expect(return_to_working_time(Time.new(2020, 10, 25, 1, 0, 0, "+01:00"))).to eq(Time.new(2020, 10, 25, 1, 0, 0, "+02:00"))
    end
  end

  describe '#working_day?' do
    it 'returns true on working day' do
      expect(working_day?(Date.new(2014, 4, 7))).to be(true)
    end

    it 'skips holidays' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      expect(working_day?(Date.new(2014, 5, 1))).to be(false)
    end

    it 'skips non working days' do
      expect(working_day?(Date.new(2014, 4, 6))).to be(false)
    end
  end

  describe '#in_working_hours?' do
    it 'returns false in non-working day' do
      WorkingHours::Config.holidays = [Date.new(2014, 5, 1)]
      expect(in_working_hours?(Time.utc(2014, 5, 1, 12, 0))).to be(false)
      expect(in_working_hours?(Time.utc(2014, 6, 1, 12, 0))).to be(false)
    end

    it 'returns true during working hours' do
      expect(in_working_hours?(Time.utc(2014, 4, 7, 9, 0))).to be(true)
      expect(in_working_hours?(Time.utc(2014, 4, 7, 16, 59))).to be(true)
    end

    it 'returns false outside working hours' do
      expect(in_working_hours?(Time.utc(2014, 4, 7, 8, 59))).to be(false)
      expect(in_working_hours?(Time.utc(2014, 4, 7, 17, 0))).to be(false)
    end

    it 'works with multiple timespan' do
      WorkingHours::Config.working_hours = {mon: {'07:00' => '12:00', '13:00' => '18:00'}}
      expect(in_working_hours?(Time.utc(2014, 4, 7, 11, 59))).to be(true)
      expect(in_working_hours?(Time.utc(2014, 4, 7, 12, 0))).to be(false)
      expect(in_working_hours?(Time.utc(2014, 4, 7, 12, 59))).to be(false)
      expect(in_working_hours?(Time.utc(2014, 4, 7, 13, 0))).to be(true)
    end

    it 'works with any timezone' do
      # Monday 00:00 am UTC is 09:00 am Tokyo, working time !
      WorkingHours::Config.time_zone = 'Tokyo'
      expect(in_working_hours?(Time.utc(2014, 4, 7, 0, 0))).to be(true)
    end

    context 'with holiday hours' do
      before do
        WorkingHours::Config.working_hours = { thu: { '08:00' => '18:00' }, fri: { '08:00' => '18:00' } }
        WorkingHours::Config.holiday_hours = { Date.new(2019, 12, 27) => { '10:00' => '20:00' } }
      end

      it 'returns true during working hours' do
        expect(in_working_hours?(Time.utc(2019, 12, 26, 9))).to be(true)
        expect(in_working_hours?(Time.utc(2019, 12, 27, 19))).to be(true)
      end

      it 'returns false outside working hours' do
        expect(in_working_hours?(Time.utc(2019, 12, 26, 7))).to be(false)
        expect(in_working_hours?(Time.utc(2019, 12, 27, 9))).to be(false)
      end
    end
  end

  describe '#working_days_between' do
    it 'returns 0 if same date' do
      expect(working_days_between(
        Date.new(1991, 11, 15), # friday
        Date.new(1991, 11, 15)
      )).to eq(0)
    end

    it 'returns 0 if time in same day' do
      expect(working_days_between(
        Time.utc(1991, 11, 15, 8), # friday
        Time.utc(1991, 11, 15, 4)
      )).to eq(0)
    end

    it 'counts working days' do
      expect(working_days_between(
        Date.new(1991, 11, 15), # friday to friday
        Date.new(1991, 11, 22)
      )).to eq(5)
    end

    it 'returns negative if params are reversed' do
      expect(working_days_between(
        Date.new(1991, 11, 22), # friday to friday
        Date.new(1991, 11, 15)
      )).to eq(-5)
    end

    context 'consider time at end of day' do
      it 'returns 0 from friday to saturday' do
        expect(working_days_between(
          Date.new(1991, 11, 15), # friday to saturday
          Date.new(1991, 11, 16)
        )).to eq(0)
      end

      it 'returns 1 from sunday to monday' do
        expect(working_days_between(
          Date.new(1991, 11, 17), # sunday to monday
          Date.new(1991, 11, 18)
        )).to eq(1)
      end
    end
  end

  describe '#working_time_between' do
    it 'returns 0 if same time' do
      expect(working_time_between(
        Time.utc(2014, 4, 7, 8),
        Time.utc(2014, 4, 7, 8)
      )).to eq(0)
    end

    it 'returns 0 during non working time' do
      expect(working_time_between(
        Time.utc(2014, 4, 11, 20), # Friday evening
        Time.utc(2014, 4, 14, 5) # Monday early
      )).to eq(0)
    end

    it 'ignores miliseconds' do
      expect(working_time_between(
        Time.utc(2014, 4, 13, 9, 10, 24.01),
        Time.utc(2014, 4, 14, 9, 10, 24.02),
      )).to eq(624)
    end

    it 'returns distance in same period' do
      expect(working_time_between(
        Time.utc(2014, 4, 7, 10),
        Time.utc(2014, 4, 7, 15)
      )).to eq(5.hours)
    end

    it 'returns negative if params are reversed' do
      expect(working_time_between(
        Time.utc(2014, 4, 7, 15),
        Time.utc(2014, 4, 7, 10)
      )).to eq(-5.hours)
    end

    it 'returns full day if outside period' do
      expect(working_time_between(
        Time.utc(2014, 4, 7, 7),
        Time.utc(2014, 4, 7, 20)
      )).to eq(8.hours)
    end

    it 'supports midnight' do
      WorkingHours::Config.working_hours = {:mon => {'00:00' => '24:00'}}
      expect(working_time_between(
        Time.utc(2014, 4, 6, 12),
        Time.utc(2016, 4, 6, 12)
      )).to eq(24.hours * 105) # 105 complete mondays in 2 years
    end

    it 'handles multiple timespans' do
      WorkingHours::Config.working_hours = {
        mon: {'07:00' => '12:00', '13:00' => '18:00'}
      }
      expect(working_time_between(
        Time.utc(2014, 4, 7, 11, 59),
        Time.utc(2014, 4, 7, 13, 1)
      )).to eq(2.minutes)
      expect(working_time_between(
        Time.utc(2014, 4, 7, 11),
        Time.utc(2014, 4, 14, 13)
      )).to eq(11.hours)
    end

    it 'works with any timezone (converts to config)' do
      expect(working_time_between(
        Time.new(2014, 4, 7, 1, 0, 0, "-09:00"), # Monday 10am in UTC
        Time.new(2014, 4, 7, 15, 0, 0, "-04:00"), # Monday 7pm in UTC
      )).to eq(7.hours)
    end

    it 'uses precise computation to avoid useless loops' do
      # +200 usec on each time, using floating point would cause
      # precision issues and require several iterations
      expect(self).to receive(:advance_to_working_time).twice.and_call_original
      expect(working_time_between(
        Time.utc(2014, 4, 7, 5, 0, 0, 200),
        Time.utc(2014, 4, 7, 15, 0, 0, 200),
      )).to eq(6.hours)
    end

    it 'works across positive time shifts' do
      WorkingHours::Config.working_hours = {sun: {'08:00' => '21:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      expect(working_time_between(
        Time.utc(2020, 3, 29, 1, 0),
        Time.utc(2020, 3, 30, 0, 0),
      )).to eq(13.hours)
    end

    it 'works across negative time shifts' do
      WorkingHours::Config.working_hours = {sun: {'08:00' => '21:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      expect(working_time_between(
        Time.utc(2019, 10, 27, 1, 0),
        Time.utc(2019, 10, 28, 0, 0),
      )).to eq(13.hours)
    end

    it 'works across time shifts + midnight' do
      WorkingHours::Config.working_hours = {sun: {'00:00' => '24:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      expect(working_time_between(
        Time.utc(2020, 10, 24, 22, 0),
        Time.utc(2020, 10, 25, 23, 0),
      )).to eq(24.hours)
    end

    it 'works across multiple time shifts' do
      WorkingHours::Config.working_hours = {sun: {'08:00' => '21:00'}}
      WorkingHours::Config.time_zone = 'Paris'
      expect(working_time_between(
        Time.utc(2002, 10, 27, 6, 0),
        Time.utc(2021, 10, 30, 0, 0),
      )).to eq(12896.hours)
    end

    it 'do not cause infinite loop if the time is not advancing properly' do
      # simulate some computation/precision error
      expect(self).to receive(:advance_to_working_time).twice do |time|
        time.change(hour: 9) - 0.0001
      end
      expect { working_time_between(
        Time.utc(2014, 4, 7, 5, 0, 0),
        Time.utc(2014, 4, 7, 15, 0, 0),
      ) }.to raise_error(RuntimeError, /Invalid loop detected in working_time_between \(from=2014-04-07T08:59:59.999/)
    end

    # generates two times with +0ms, +250ms, +500ms, +750ms and +1s
    # then for each combination compare the result with a ruby diff
    context 'with precise miliseconds timings' do
      reference = Time.utc(2014, 4, 7, 10)
      0.step(1.0, 0.25) do |offset1|
        0.step(1.0, 0.25) do |offset2|
          from = reference + offset1
          to = reference + offset2
          it "returns expected value (#{(to - from).round}) for #{offset1} — #{offset2} interval" do
            expect(working_time_between(from, to)).to eq((to - from).round)
          end
        end
      end
    end

    context 'with holiday hours' do
      before do
        WorkingHours::Config.working_hours = { mon: { '08:00' => '18:00' }, tue: { '08:00' => '18:00' } }
        WorkingHours::Config.holiday_hours = { Date.new(2014, 4, 7) => { '10:00' => '12:00', '14:00' => '17:00' } }
      end

      context 'time is before the start of holiday hours' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 8),
            Time.utc(2014, 4, 7, 9)
          )).to eq(0)
        end
      end

      context 'time is between holiday hours' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 13),
            Time.utc(2014, 4, 7, 13, 30)
          )).to eq(0)
        end
      end

      context 'time is after the end of holiday hours' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 19),
            Time.utc(2014, 4, 7, 20)
          )).to eq(0)
        end
      end

      context 'time is before the start of the holiday hours' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 9),
            Time.utc(2014, 4, 7, 12)
          )).to eq(7200)
        end
      end

      context 'time crosses overridden holiday hours at midday' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 9),
            Time.utc(2014, 4, 7, 14)
          )).to eq(7200)
        end
      end

      context 'time crosses overridden holiday hours at midday' do
        it 'does not count holiday hours as working time' do
          expect(working_time_between(
            Time.utc(2014, 4, 7, 12),
            Time.utc(2014, 4, 7, 18)
          )).to eq(10800)
        end
      end
    end
  end
end
