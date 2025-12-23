# `Date`

A subclass of `Object` that includes the `Comparable` module and easily handles date.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'date'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install date

## Usage

```ruby
require 'date'
```

A `Date` object is created with `Date::new`, `Date::jd`, `Date::ordinal`, `Date::commercial`, `Date::parse`, `Date::strptime`, `Date::today`, `Time#to_date`, etc.

```ruby
require 'date'

Date.new(2001,2,3)
	    #=> #<Date: 2001-02-03 ...>
Date.jd(2451944)
	    #=> #<Date: 2001-02-03 ...>
Date.ordinal(2001,34)
	    #=> #<Date: 2001-02-03 ...>
Date.commercial(2001,5,6)
	    #=> #<Date: 2001-02-03 ...>
Date.parse('2001-02-03')
	    #=> #<Date: 2001-02-03 ...>
Date.strptime('03-02-2001', '%d-%m-%Y')
	    #=> #<Date: 2001-02-03 ...>
Time.new(2001,2,3).to_date
	    #=> #<Date: 2001-02-03 ...>
```

All `Date` objects are immutable; hence cannot modify themselves.

The concept of a date object can be represented as a tuple of the day count, the offset and the day of calendar reform.

The day count denotes the absolute position of a temporal dimension. The offset is relative adjustment, which determines decoded local time with the day count. The day of calendar reform denotes the start day of the new style. The old style of the West is the Julian calendar which was adopted by Caesar. The new style is the Gregorian calendar, which is the current civil calendar of many countries.

The day count is virtually the astronomical Julian day number. The offset in this class is usually zero, and cannot be specified directly.

A `Date` object can be created with an optional argument, the day of calendar reform as a Julian day number, which should be 2298874 to 2426355 or negative/positive infinity. The default value is `Date::ITALY` (2299161=1582-10-15). See also sample/cal.rb.

```
$ ruby sample/cal.rb -c it 10 1582
October 1582
S  M Tu  W Th  F  S
1  2  3  4 15 16
17 18 19 20 21 22 23
24 25 26 27 28 29 30
31
```

```
$ ruby sample/cal.rb -c gb  9 1752
September 1752
S  M Tu  W Th  F  S
1  2 14 15 16
17 18 19 20 21 22 23
24 25 26 27 28 29 30
```

A `Date` object has various methods. See each reference.

```ruby
d = Date.parse('3rd Feb 2001')
					#=> #<Date: 2001-02-03 ...>
d.year			#=> 2001
d.mon			#=> 2
d.mday			#=> 3
d.wday			#=> 6
d += 1			#=> #<Date: 2001-02-04 ...>
d.strftime('%a %d %b %Y')	#=> "Sun 04 Feb 2001"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby/date.

## License

The gem is available as open source under the terms of the [2-Clause BSD License](https://opensource.org/licenses/BSD-2-Clause).
