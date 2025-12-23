
# fugit

[![tests](https://github.com/floraison/fugit/workflows/test/badge.svg)](https://github.com/floraison/fugit/actions)
[![Gem Version](https://badge.fury.io/rb/fugit.svg)](http://badge.fury.io/rb/fugit)

Time tools for [flor](https://github.com/floraison/flor) and the floraison group.

It uses [et-orbi](https://github.com/floraison/et-orbi) to represent time instances and [raabro](https://github.com/floraison/raabro) as a basis for its parsers.

Fugit is a core dependency of [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) >= 3.5.


## Related projects

### Sister projects

The intersection of those two projects is where fugit is born:

* [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) - a cron/at/in/every/interval in-process scheduler, in fact, it's the father project to this fugit project
* [flor](https://github.com/floraison/flor) - a Ruby workflow engine, fugit provides the foundation for its time scheduling capabilities

### Similar, sometimes overlapping projects

* [chronic](https://github.com/mojombo/chronic) - a pure Ruby natural language date parser
* [parse-cron](https://github.com/siebertm/parse-cron) - parses cron expressions and calculates the next occurrence after a given date
* [ice_cube](https://github.com/seejohnrun/ice_cube) - Ruby date recurrence library
* [ISO8601](https://github.com/arnau/ISO8601) - Ruby parser to work with ISO8601 dateTimes and durations
* [chrono](https://github.com/r7kamura/chrono) - a chain of logics about chronology
* [CronCalc](https://github.com/mizinsky/cron_calc) - calculates cron job occurrences
* [Recurrence](https://github.com/fnando/recurrence) - a simple library to handle recurring events
* ...

### Projects using fugit

* [arask](https://github.com/Ebbe/arask) - "Automatic RAils taSKs" uses fugit to parse cron strings
* [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron) - uses fugit to parse cron strings since version 1.0.0, it was using rufus-scheduler previously
* [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) - as seen above
* [flor](https://github.com/floraison/flor) - used in the [cron](https://github.com/floraison/flor/blob/master/doc/procedures/cron.md) procedure
* [que-scheduler](https://github.com/hlascelles/que-scheduler) - a reliable job scheduler for [que](https://github.com/chanks/que)
* [serial_scheduler](https://github.com/grosser/serial_scheduler) - ruby task scheduler without threading
* [delayed_cron_job](https://github.com/codez/delayed_cron_job) - an extension to Delayed::Job that allows you to set cron expressions for your jobs
* [GoodJob](https://github.com/bensheldon/good_job) - a multithreaded, Postgres-based, Active Job backend for Ruby on Rails
* [Solid Queue](https://github.com/rails/solid_queue) - a DB-based queuing backend for Active Job, designed with simplicity and performance in mind
* ...

## `Fugit.parse(s)`

The simplest way to use fugit is via `Fugit.parse(s)`.

```ruby
require 'fugit'

Fugit.parse('0 0 1 jan *').class         # ==> ::Fugit::Cron
Fugit.parse('12y12M').class              # ==> ::Fugit::Duration

Fugit.parse('2017-12-12').class          # ==> ::EtOrbi::EoTime
Fugit.parse('2017-12-12 UTC').class      # ==> ::EtOrbi::EoTime

Fugit.parse('every day at noon').class   # ==> ::Fugit::Cron
```

If fugit cannot extract a cron, duration or point in time out of the string, it will return nil.
```ruby
Fugit.parse('nada')
  # ==> nil
```

## `Fugit.do_parse(s)`

`Fugit.do_parse(s)` is equivalent to `Fugit.parse(s)`, but instead of returning nil, it raises an error if the given string contains no time information.
```ruby
Fugit.do_parse('nada')
  # ==> /home/jmettraux/w/fugit/lib/fugit/parse.rb:32
  #     :in `do_parse': found no time information in "nada" (ArgumentError)
```

## parse_cron, parse_in, parse_at, parse_duration, and parse_nat

```ruby
require 'fugit'

Fugit.parse_cron('0 0 1 jan *').class       # ==> ::Fugit::Cron
Fugit.parse_duration('12y12M').class        # ==> ::Fugit::Duration

Fugit.parse_at('2017-12-12').class          # ==> ::EtOrbi::EoTime
Fugit.parse_at('2017-12-12 UTC').class      # ==> ::EtOrbi::EoTime

Fugit.parse_nat('every day at noon').class  # ==> ::Fugit::Cron
```

## do_parse_cron, do_parse_in, do_parse_at, do_parse_duration, and do_parse_nat

As `Fugit.parse(s)` returns nil when it doesn't grok its input, and `Fugit.do_parse(s)` fails when it doesn't grok, each of the `parse_` methods has its partner `do_parse_` method.

## parse_cronish and do_parse_cronish

Sometimes you know a cron expression or an "every" natural expression will come in and you want to discard the rest.

```ruby
require 'fugit'

Fugit.parse_cronish('0 0 1 jan *').class             # ==> ::Fugit::Cron
Fugit.parse_cronish('every saturday at noon').class  # ==> ::Fugit::Cron

Fugit.parse_cronish('12y12M')        # ==> nil
```

`.parse_cronish(s)` will return a `Fugit::Cron` instance or else nil.

`.do_parse_cronish(s)` will return a `Fugit::Cron` instance or else fail with an `ArgumentError`.

Introduced in fugit 1.8.0.

## `Fugit::Cron`

A class `Fugit::Cron` to parse cron strings and then `#next_time` and `#previous_time` to compute the next or the previous occurrence respectively.

There is also a `#brute_frequency` method which returns an array `[ shortest delta, longest delta, occurrence count ]` where delta is the time between two occurrences.

```ruby
require 'fugit'

c = Fugit::Cron.parse('0 0 * *  sun')
  # or
c = Fugit::Cron.new('0 0 * *  sun')

p Time.now  # => 2017-01-03 09:53:27 +0900

p c.next_time.to_s      # => 2017-01-08 00:00:00 +0900
p c.previous_time.to_s  # => 2017-01-01 00:00:00 +0900

p c.next_time(Time.parse('2024-06-01')).to_s
  # => "2024-06-02 00:00:00 +0900"
p c.previous_time(Time.parse('2024-06-01')).to_s
  # => "2024-05-26 00:00:00 +0900"
    #
    # `Fugit::Cron#next_time` and `#previous_time` accept a "start time"

c = Fugit.parse_cron('0 12 * * mon#2')

  # `#next` and `#prev` return Enumerable instances
  #
  # These two methods are available since fugit 1.10.0.
  #
c.next(Time.parse('2024-02-16 12:00:00'))
  .take(3)
  .map(&:to_s)
    # => [ '2024-03-11 12:00:00',
    #      '2024-04-08 12:00:00',
    #      '2024-05-13 12:00:00' ]
c.prev(Time.parse('2024-02-16 12:00:00'))
  .take(3)
  .map(&:to_s)
    # => [ '2024-02-12 12:00:00',
    #      '2024-01-08 12:00:00',
    #      '2023-12-11 12:00:00' ]

  # `#within` accepts a time range and returns an array of Eo::EoTime
  # instances that correspond to the occurrences of the cron within
  # the time range
  #
  # This method is available since fugit 1.10.0.
  #
c.within(Time.parse('2024-02-16 12:00')..Time.parse('2024-08-01 12:00'))
  .map(&:to_s)
    # => [ '2024-03-11 12:00:00',
    #      '2024-04-08 12:00:00',
    #      '2024-05-13 12:00:00',
    #      '2024-06-10 12:00:00',
    #      '2024-07-08 12:00:00' ]

p c.brute_frequency  # => [ 604800, 604800, 53 ]
                     #    [ delta min, delta max, occurrence count ]
p c.rough_frequency  # => 7 * 24 * 3600 (7d rough frequency)

p c.match?(Time.parse('2017-08-06'))  # => true
p c.match?(Time.parse('2017-08-07'))  # => false
p c.match?('2017-08-06')              # => true
p c.match?('2017-08-06 12:00')        # => false
```

Example of cron strings understood by fugit:
```ruby
'5 0 * * *'         # 5 minutes after midnight, every day
'15 14 1 * *'       # at 1415 on the 1st of every month
'0 22 * * 1-5'      # at 2200 on weekdays
'0 22 * * mon-fri'  # idem
'23 0-23/2 * * *'   # 23 minutes after 00:00, 02:00, 04:00, ...

'@yearly'    # turns into '0 0 1 1 *'
'@monthly'   # turns into '0 0 1 * *'
'@weekly'    # turns into '0 0 * * 0'
'@daily'     # turns into '0 0 * * *'
'@midnight'  # turns into '0 0 * * *'
'@hourly'    # turns into '0 * * * *'

'0 0 L * *'     # last day of month at 00:00
'0 0 last * *'  # idem
'0 0 -7-L * *'  # from the seventh to last to the last day of month at 00:00

# and more...
```

Please note that `'15/30 * * * *'` is interpreted as `'15-59/30 * * * *'` since fugit 1.4.6.

### the first Monday of the month

Fugit tries to follow the `man 5 crontab` documentation.

There is a surprising thing about this canon, all the columns are joined by ANDs, except for monthday and weekday which are joined together by OR if they are both set (they are not `*`).

Many people (me included) [are suprised](https://superuser.com/questions/428807/run-a-cron-job-on-the-first-monday-of-every-month) when they try to specify "at 05:00 on the first Monday of the month" as `0 5 1-7 * 1` or `0 5 1-7 * mon` and the results are off.

The man page says:

> Note: The day of a command's execution can be specified by
> two fields -- day of month, and day of week. If both fields
> are restricted (ie, are not *), the command will be run when
> either field matches the current time.
> For example, ``30 4 1,15 * 5'' would cause a command to be run
> at 4:30 am on the 1st and 15th of each month, plus every Friday.

Fugit follows this specification.

Since fugit 1.7.0, by adding `&` right after a day specifier, the `day-of-month OR day-of-week` becomes `day-of-month AND day-of-week`.

```ruby
# standard cron

p Fugit.parse_cron('0 0 */2 * 1-5').next_time('2022-08-09').to_s
  # ==> "2022-08-10 00:00:00 +0900"

# with an &

p Fugit.parse_cron('0 0 */2 * 1-5&').next_time('2022-08-09').to_s # or
p Fugit.parse_cron('0 0 */2& * 1-5').next_time('2022-08-09').to_s
p Fugit.parse_cron('0 0 */2& * 1-5&').next_time('2022-08-09').to_s
  # ==> "2022-08-11 00:00:00 +0900"


# standard cron

p Fugit.parse_cron('59 6 1-7 * 2').next_time('2020-03-15').to_s
  # ==> "2020-03-17 06:59:00 +0900"

# with an &

p Fugit.parse_cron('59 6 1-7 * 2&').next_time('2020-03-15').to_s
p Fugit.parse_cron('59 6 1-7& * 2').next_time('2020-03-15').to_s
p Fugit.parse_cron('59 6 1-7& * 2&').next_time('2020-03-15').to_s
  # ==> "2020-04-07 06:59:00 +0900"
```

### the hash extension

Fugit understands `0 5 * * 1#1` or `0 5 * * mon#1` as "each first Monday of the month, at 05:00".

The hash extension can only be used in the day-of-week field.

```ruby
'0 5 * * 1#1'    #
'0 5 * * mon#1'  # the first Monday of the month at 05:00

'0 6 * * 5#4,5#5'      #
'0 6 * * fri#4,fri#5'  # the 4th and 5th Fridays of the month at 06:00

'0 7 * * 5#-1'    #
'0 7 * * fri#-1'  # the last Friday of the month at 07:00

'0 7 * * 5#L'       #
'0 7 * * fri#L'     #
'0 7 * * 5#last'    #
'0 7 * * fri#last'  # the last Friday of the month at 07:00

'0 23 * * mon#2,tue'  # the 2nd Monday of the month and every Tuesday, at 23:00
```

### the modulo extension

Fugit, since 1.1.10, also understands cron strings like "`9 0 * * sun%2`" which can be read as "every other Sunday at 9am".

The modulo extension can only be used in the day-of-week field.

For odd Sundays, one can write `9 0 * * sun%2+1`.

It can be combined, as in `9 0 * * sun%2,tue%3+2`

But what does it reference to? It starts at 1 on 2019-01-01.

```ruby
require 'et-orbi' # >= 1.1.8

# the reference
p EtOrbi.parse('2019-01-01').wday       # => 2
p EtOrbi.parse('2019-01-01').rweek      # => 1
p EtOrbi.parse('2019-01-01').rweek % 2  # => 1

# today (as of this coding...)
p EtOrbi.parse('2019-04-11').wday       # => 4
p EtOrbi.parse('2019-04-11').rweek      # => 15
p EtOrbi.parse('2019-04-11').rweek % 2  # => 1

c = Fugit.parse('* * * * tue%2')
c.match?('2019-01-01')  # => false, since rweek % 2 == 1
c.match?('2019-01-08')  # => true, since rweek % 2 == 0

c = Fugit.parse('* * * * tue%2+1')
c.match?('2019-01-01')  # => true, since (rweek + 1) % 2 == 0
c.match?('2019-01-08')  # => false, since (rweek + 1) % 2 == 1

# ...
```

`sun%2` matches if Sunday and `current_date.rweek % 2 == 0`
`tue%3+2` matches if Tuesday and `current_date.rweek + 2 % 3 == 0`
`tue%x+y` matches if Tuesday and `current_date.rweek + y % x == 0`


### the second extension

Fugit accepts cron strings with five elements, `minute hour day-of-month month day-of-week`, the standard cron format or six elements `second minute hour day-of-month month day-of-week`.

```ruby
c = Fugit.parse('* * * * *') # every minute
c = Fugit.parse('5 * * * *') # every hour at minute 5
c = Fugit.parse('* * * * * *') # every second
c = Fugit.parse('5 * * * * *') # every minute at second 5
```


## `Fugit::Duration`

A class `Fugit::Duration` to parse duration strings (vanilla [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) ones and [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) ones).

Provides duration arithmetic tools.

```ruby
require 'fugit'

d = Fugit::Duration.parse('1y2M1d4h')

p d.to_plain_s  # => "1Y2M1D4h"
p d.to_iso_s    # => "P1Y2M1DT4H" ISO 8601 duration
p d.to_long_s   # => "1 year, 2 months, 1 day, and 4 hours"

d += Fugit::Duration.parse('1y1h')

p d.to_long_s  # => "2 years, 2 months, 1 day, and 5 hours"

d += 3600

p d.to_plain_s  # => "2Y2M1D5h3600s"

p Fugit::Duration.parse('1y2M1d4h').to_sec # => 36820800
```

There is a `#deflate` method

```ruby
Fugit::Duration.parse(1000).to_plain_s # => "1000s"
Fugit::Duration.parse(3600).to_plain_s # => "3600s"
Fugit::Duration.parse(1000).deflate.to_plain_s # => "16m40s"
Fugit::Duration.parse(3600).deflate.to_plain_s # => "1h"

# or event shorter
Fugit.parse(1000).deflate.to_plain_s # => "16m40s"
Fugit.parse(3600).deflate.to_plain_s # => "1h"
```

There is also an `#inflate` method

```ruby
Fugit::Duration.parse('1h30m12').inflate.to_plain_s # => "5412s"
Fugit.parse('1h30m12').inflate.to_plain_s # => "5412s"

Fugit.parse('1h30m12').to_sec # => 5412
Fugit.parse('1h30m12').to_sec.to_s + 's' # => "5412s"
```

The `to_*_s` methods are also available as class methods:
```ruby
p Fugit::Duration.to_plain_s('1y2M1d4h')
  # => "1Y2M1D4h"
p Fugit::Duration.to_iso_s('1y2M1d4h')
  # => "P1Y2M1DT4H" ISO 8601 duration
p Fugit::Duration.to_long_s('1y2M1d4h')
  # => "1 year, 2 months, 1 day, and 4 hours"
```

## `Fugit::At`

Points in time are parsed and given back as EtOrbi::EoTime instances.

```ruby
Fugit::At.parse('2017-12-12').to_s
  # ==> "2017-12-12 00:00:00 +0900" (at least here in Hiroshima)

Fugit::At.parse('2017-12-12 12:00:00 America/New_York').to_s
  # ==> "2017-12-12 12:00:00 -0500"
```

Directly with `Fugit.parse_at(s)` is OK too:
```ruby
Fugit.parse_at('2017-12-12 12:00:00 America/New_York').to_s
  # ==> "2017-12-12 12:00:00 -0500"
```

Directly with `Fugit.parse(s)` is OK too:
```ruby
Fugit.parse('2017-12-12 12:00:00 America/New_York').to_s
  # ==> "2017-12-12 12:00:00 -0500"
```

## `Fugit::Nat`

Fugit understand some kind of "natural" language:

For example, those "every" get turned into `Fugit::Cron` instances:
```ruby
Fugit::Nat.parse('every day at five')                         # ==> '0 5 * * *'
Fugit::Nat.parse('every weekday at five')                     # ==> '0 5 * * 1,2,3,4,5'
Fugit::Nat.parse('every day at 5 pm')                         # ==> '0 17 * * *'
Fugit::Nat.parse('every tuesday at 5 pm')                     # ==> '0 17 * * 2'
Fugit::Nat.parse('every wed at 5 pm')                         # ==> '0 17 * * 3'
Fugit::Nat.parse('every day at 16:30')                        # ==> '30 16 * * *'
Fugit::Nat.parse('every day at 16:00 and 18:00')              # ==> '0 16,18 * * *'
Fugit::Nat.parse('every day at noon')                         # ==> '0 12 * * *'
Fugit::Nat.parse('every day at midnight')                     # ==> '0 0 * * *'
Fugit::Nat.parse('every tuesday and monday at 5pm')           # ==> '0 17 * * 1,2'
Fugit::Nat.parse('every wed or Monday at 5pm and 11')         # ==> '0 11,17 * * 1,3'
Fugit::Nat.parse('every day at 5 pm on America/Los_Angeles')  # ==> '0 17 * * * America/Los_Angeles'
Fugit::Nat.parse('every day at 6 pm in Asia/Tokyo')           # ==> '0 18 * * * Asia/Tokyo'
Fugit::Nat.parse('every 3 hours')                             # ==> '0 */3 * * *'
Fugit::Nat.parse('every 4 months')                            # ==> '0 0 1 */4 *'
Fugit::Nat.parse('every 5 minutes')                           # ==> '*/5 * * * *'
Fugit::Nat.parse('every 15s')                                 # ==> '*/15 * * * * *'
```

Directly with `Fugit.parse(s)` is OK too:
```ruby
Fugit.parse('every day at five')  # ==> Fugit::Cron instance '0 5 * * *'
```

### Ambiguous nats

Not all strings result in a clean, single, cron expression. The `multi: false|true|:fail` argument to `Fugit::Nat.parse` could help.

```ruby
Fugit::Nat.parse('every day at 16:00 and 18:00')
  .to_cron_s
    # ==> '0 16,18 * * *' (a single Fugit::Cron instances)
Fugit::Nat.parse('every day at 16:00 and 18:00', multi: true)
  .collect(&:to_cron_s)
    # ==> [ '0 16,18 * * *' ] (array of Fugit::Cron instances, here only one)

Fugit::Nat.parse('every day at 16:15 and 18:30')
  .to_cron_s
    # ==> '15 16 * * *' (a single of Fugit::Cron instances)
Fugit::Nat.parse('every day at 16:15 and 18:30', multi: true)
  .collect(&:to_cron_s)
    # ==> [ '15 16 * * *', '30 18 * * *' ] (two Fugit::Cron instances)

Fugit::Nat.parse('every day at 16:15 and 18:30', multi: :fail)
  # ==> ArgumentError: multiple crons in "every day at 16:15 and 18:30"
  #     (15 16 * * * | 30 18 * * *)
Fugit::Nat.parse('every day at 16:15 nada 18:30', multi: true)
  # ==> nil
```

`multi: true` indicates to `Fugit::Nat` that an array of `Fugit::Cron` instances is expected as a result.

`multi: :fail` tells `Fugit::Nat.parse` to fail if the result is more than 1 `Fugit::Cron` instances.

`multi: false` is the default behaviour, return a single `Fugit::Cron` instance or nil when it cannot parse.

Please note that "nat" input is limited to 256 characters (fugit 1.11.1).

### Nat Midnight

`"Every day at midnight"` is supported, but `"Every monday at midnight"` will be interpreted (as of Fugit <= 1.4.x) as `"Every monday at 00:00"`. Sorry about that.


### 12 AM and PM

How does fugit react with `"12 am"`, `"12 pm"`, `"12 midnight"`, etc?

```ruby
require 'fugit'

p Fugit.parse('every day at 12am').original  # ==> "0 0 * * *"
p Fugit.parse('every day at 12pm').original  # ==> "0 12 * * *"

p Fugit.parse('every day at 12:00am').original   # ==> "0 0 * * *"
p Fugit.parse('every day at 12:00pm').original   # ==> "0 12 * * *"
p Fugit.parse('every day at 12:00 am').original  # ==> "0 0 * * *"
p Fugit.parse('every day at 12:00 pm').original  # ==> "0 12 * * *"
p Fugit.parse('every day at 12:15am').original   # ==> "15 0 * * *"
p Fugit.parse('every day at 12:15pm').original   # ==> "15 12 * * *"
p Fugit.parse('every day at 12:15 am').original  # ==> "15 0 * * *"
p Fugit.parse('every day at 12:15 pm').original  # ==> "15 12 * * *"

p Fugit.parse('every day at 12 noon').original         # ==> "0 12 * * *"
p Fugit.parse('every day at 12 midnight').original     # ==> "0 24 * * *"
p Fugit.parse('every day at 12:00 noon').original      # ==> "0 12 * * *"
p Fugit.parse('every day at 12:00 midnight').original  # ==> "0 24 * * *"
p Fugit.parse('every day at 12:15 noon').original      # ==> "15 12 * * *"
p Fugit.parse('every day at 12:15 midnight').original  # ==> "15 24 * * *"

  # as of fugit 1.7.2
```


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

