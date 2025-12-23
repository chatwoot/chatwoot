# WorkingHours

[![Build Status](https://travis-ci.com/Intrepidd/working_hours.svg?branch=master)](https://travis-ci.com/Intrepidd/working_hours)

A modern ruby gem allowing to do time calculation with working hours.

Compatible and tested with:
- Ruby `2.4`, `2.5`, `2.6`, `2.7`, `3.0`, JRuby `9.2`
- ActiveSupport `4.x`, `5.x`, `6.x`

## Installation

Gemfile:

```ruby
gem 'working_hours'
```

## Usage

```ruby
require 'working_hours'

# Move forward
1.working.day.from_now
2.working.hours.from_now
15.working.minutes.from_now

# Move backward
1.working.day.ago
2.working.hours.ago
15.working.minutes.ago

# Start from custom Date or Time
Date.new(2014, 12, 31) + 8.working.days # => Mon, 12 Jan 2015
Time.utc(2014, 8, 4, 8, 32) - 4.working.hours # => 2014-08-01 13:00:00

# Compute working days between two dates
friday = Date.new(2014, 10, 17)
monday = Date.new(2014, 10, 20)
friday.working_days_until(monday) # => 1
# Time is considered at end of day, so:
# - friday to saturday = 0 working days
# - sunday to monday = 1 working days

# Compute working duration (in seconds) between two times
from = Time.utc(2014, 8, 3, 8, 32) # sunday 8:32am
to = Time.utc(2014, 8, 4, 10, 32) # monday 10:32am
from.working_time_until(to) # => 5520 (1.hour + 32.minutes)

# Know if a day is worked
Date.new(2014, 12, 28).working_day? # => false

# Know if a time is worked
Time.utc(2014, 8, 4, 7, 16).in_working_hours? # => false

# Advance to next working time
WorkingHours.advance_to_working_time(Time.utc(2014, 8, 4, 7, 16)) # => Mon, 04 Aug 2014 09:00:00 UTC +00:00

# Advance to next closing time
WorkingHours.advance_to_closing_time(Time.utc(2014, 8, 4, 7, 16)) # => Mon, 04 Aug 2014 17:00:00 UTC +00:00
WorkingHours.advance_to_closing_time(Time.utc(2014, 8, 4, 10, 16)) # => Mon, 04 Aug 2014 17:00:00 UTC +00:00
WorkingHours.advance_to_closing_time(Time.utc(2014, 8, 4, 18, 16)) # => Tue, 05 Aug 2014 17:00:00 UTC +00:00

# Next working time
sunday = Time.utc(2014, 8, 3)
monday = WorkingHours.next_working_time(sunday) # => Mon, 04 Aug 2014 09:00:00 UTC +00:00
tuesday = WorkingHours.next_working_time(monday) # => Tue, 05 Aug 2014 09:00:00 UTC +00:00

# Return to previous working time
WorkingHours.return_to_working_time(Time.utc(2014, 8, 4, 7, 16)) # => Fri, 01 Aug 2014 17:00:00 UTC +00:00
```

## Configuration

The working hours configuration is thread safe and consists of a hash defining working periods for each day, a time zone and a list of days off. You can set it once, for example in a initializer for rails:

```ruby
# Configure working hours
WorkingHours::Config.working_hours = {
  :tue => {'09:00' => '12:00', '13:00' => '17:00'},
  :wed => {'09:00' => '12:00', '13:00' => '17:00'},
  :thu => {'09:00' => '12:00', '13:00' => '17:00'},
  :fri => {'09:00' => '12:00', '13:00' => '17:05:30'},
  :sat => {'19:00' => '24:00'}
}

# Configure timezone (uses activesupport, defaults to UTC)
WorkingHours::Config.time_zone = 'Paris'

# Configure holidays
WorkingHours::Config.holidays = [Date.new(2014, 12, 31)]
```

Or you can set it for the duration of a block with the `with_config` method, this is particularly useful with `around_filter`:

```ruby
WorkingHours::Config.with_config(working_hours: {mon:{'09:00' => '18:00'}}, holidays: [], time_zone: 'Paris') do
  # Intense calculations
end
```
``with_config`` uses keyword arguments, you can pass all or some of the supported arguments :
- ``working_hours``
- ``holidays``
- ``time_zone``

### Holiday hours
Sometimes you need to configure different working hours as a one-off, e.g. the working day might end earlier on Christmas Eve.

You can configure this with the `holiday_hours` option, either as an override on the existing working hours, or as a set of hours that *are* being worked on a holiday day.

If *any* hours are set for a calendar day in `holiday_hours`, then the `working_hours` for that day will be ignored, and only the entries in `holiday_hours` taken into consideration.

```ruby
# Configure holiday hours
WorkingHours::Config.holiday_hours = {Date.new(2020, 12, 24) => {'09:00' => '12:00', '13:00' => '15:00'}}
```

### Handling errors

If the configuration is erroneous, an ``WorkingHours::InvalidConfiguration`` exception will be raised containing the appropriate error message.

You can also access the error code in case you want to implement custom behavior or changing one specific message, e.g:

```ruby
rescue WorkingHours::InvalidConfiguration => e
  if e.error_code == :empty
    raise StandardError.new "Config is required"
  end
  raise e
end
```

## No core extensions / monkey patching

Core extensions (monkey patching to add methods on Time, Date, Numbers, etc.) are handy but not appreciated by everyone. WorkingHours can also be used **without any monkey patching**:

```ruby
require 'working_hours/module'

# Move forward
WorkingHours::Duration.new(1, :days).from_now
WorkingHours::Duration.new(2, :hours).from_now
WorkingHours::Duration.new(15, :minutes).from_now

# Move backward
WorkingHours::Duration.new(1, :days).ago
WorkingHours::Duration.new(2, :hours).ago
WorkingHours::Duration.new(15, :minutes).ago

# Start from custom Date or Time
WorkingHours::Duration.new(8, :days).since(Date.new(2014, 12, 31)) # => Mon, 12 Jan 2015
WorkingHours::Duration.new(4, :hours).until(Time.utc(2014, 8, 4, 8, 32)) # => 2014-08-01 13:00:00

# Compute working days between two dates
friday = Date.new(2014, 10, 17)
monday = Date.new(2014, 10, 20)
WorkingHours.working_days_between(friday, monday) # => 1
# Time is considered at end of day, so:
# - friday to saturday = 0 working days
# - sunday to monday = 1 working days

# Compute working duration (in seconds) between two times
from = Time.utc(2014, 8, 3, 8, 32) # sunday 8:32am
to = Time.utc(2014, 8, 4, 10, 32) # monday 10:32am
WorkingHours.working_time_between(from, to) # => 5520 (1.hour + 32.minutes)

# Know if a day is worked
WorkingHours.working_day?(Date.new(2014, 12, 28)) # => false

# Know if a time is worked
WorkingHours.in_working_hours?(Time.utc(2014, 8, 4, 7, 16)) # => false
```

## Use in your class/module

If you want to use working hours only inside a specific class or module, you can include its computation methods like this:

```ruby
require 'working_hours/module'

class Order
  include WorkingHours

  def shipping_date_estimate
    Duration.new(2, :days).since(payment_received_at)
  end

  def payment_delay
    working_days_between(created_at, payment_received_at)
  end
end
```

## Timezones

This gem uses a simple but efficient approach in dealing with timezones. When you define your working hours **you have to choose** a timezone associated with it (in the config example, the working hours are in Paris time). Then, any time used in calculation will be converted to this timezone first, so you don't have to worry if your times are local or UTC as long as they are correct :)

## Alternatives

There is a gem called [business_time](https://github.com/bokmann/business_time) already available to do this kind of computation and it was of great help to us. But we decided to start another one because business_time is suffering from a few [bugs](https://github.com/bokmann/business_time/pull/84) and [inconsistencies](https://github.com/bokmann/business_time/issues/50). It also lacks essential features to us (like working minutes computation).

Another gem called [biz](https://github.com/zendesk/biz) was released after working_hours to bring some alternative.

## Contributing

1. Fork it ( http://github.com/intrepidd/working_hours/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
