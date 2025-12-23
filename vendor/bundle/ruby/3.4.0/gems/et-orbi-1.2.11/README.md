
# et-orbi

[![tests](https://github.com/floraison/et-orbi/workflows/test/badge.svg)](https://github.com/floraison/et-orbi/actions)
[![Gem Version](https://badge.fury.io/rb/et-orbi.svg)](http://badge.fury.io/rb/et-orbi)

Time zones for [fugit](https://github.com/floraison/fugit) and for [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler). Urbi et Orbi.

`EtOrbi::EoTime` instances quack like Ruby `Time` instances, but their `#zone` returns a `TZInfo::TimeZone` instance.

Getting `EoTime` instances:
```ruby
require 'et-orbi'

EtOrbi.now
  # => #<EtOrbi::EoTime:0x007f94d94 ...>
EtOrbi.now('Asia/Singapore')
  # => #<EtOrbi::EoTime:0x39c96e48 @time=nil, @zone=#<TZInfo::DataTimezone: Asia/Singapore>...>
EtOrbi.parse('2017-12-13 13:00:00 America/Jamaica')
  # => #<EtOrbi::EoTime:0x007f94d90 @zone=#<TZInfo::DataTimezone: America/Jamaica>...>
EtOrbi.make_time(Time.now)
  # => #<EtOrbi::EoTime:0x007f94d91 ...>

EtOrbi.make_time(2017, 1, 31, 12, 'Europe/Moscow').to_debug_s
  # => 'ot 2017-01-31 12:00:00 +03:00 dst:false'

EtOrbi::EoTime.new(0, 'UTC').to_s
  # => "1970-01-01 00:00:00 +0000"
EtOrbi::EoTime.new(0, 'Europe/Moscow').to_s
  # => "1970-01-01 03:00:00 +0300"
EtOrbi::EoTime.new(0, 'Europe/Moscow').to_zs
  # => "1970-01-01 03:00:00 Europe/Moscow" # "be precise in your speech"

EtOrbi.parse('1970-01-01 03:00:00 Europe/Moscow')
  # => #<EtOrbi::EoTime:0x00007fa4bc83fcd0
  #  @seconds=0.0, @zone=#<TZInfo::DataTimezone: Europe/Moscow>, @time=nil>
```

More about `EtOrbi::EoTime` instances:
```ruby
eot = EtOrbi::EoTime.new(0, 'Europe/Moscow')

eot.to_local_time.class  # => Time
eot.to_local_time.to_s   # => "1970-01-01 09:00:00 +0900" (at least on my system)

# For the rest, EtOrbi::EoTime mimicks ::Time
```

Helper methods:
```ruby
require 'et-orbi'

EtOrbi.get_tzone('Europe/Vilnius')
  # => #<TZInfo::DataTimezone: Europe/Vilnius>
EtOrbi.local_tzone
  # => #<TZInfo::TimezoneProxy: Asia/Tokyo>

EtOrbi.platform_info
  # => "(etz:nil,tnz:\"JST\",tzid:nil,rv:\"2.2.6\",rp:\"x86_64-darwin14\",eov:\"1.0.1\",
  #      rorv:nil,astz:nil,debian:nil,centos:nil,osx:\"Asia/Tokyo\")"
    #
    # etz: ENV['TZ']
    # tnz: Time.now.zone
    # tzid: defined?(TZInfo::Data)
    # rv: RUBY_VERSION
    # rp: RUBY_PLATFORM
    # eov: EtOrbi::VERSION
    # rorv: Rails::VERSION::STRING
    # astz: ActiveSupport provided Time.zone
```

### Chronic integration

By default, et-orbi relies on [Chronic](https://github.com/mojombo/chronic) to parse strings like "tomorrow" or "friday 1pm", if `Chronic` is present.

```ruby
EtOrbi.parse('tomorrow')
  # => #<EtOrbi::EoTime:0x007fbc6aa8a560
  #      @seconds=1575687600.0,
  #      @zone=#<TZInfo::TimezoneProxy: Asia/Tokyo>,
  #      @time=nil>
EtOrbi.parse('tomorrow').to_s
  # => "2019-12-07 12:00:00 +0900"
```

This is a poor design choice I replicated from [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler).

Of course this leads to [issues](https://gitlab.com/gitlab-org/gitlab/issues/37014).

It's probably better to have Chronic do its work outside of et-orbi, like in:
```ruby
EtOrbi.parse(Chronic.parse('tomorrow').to_s).to_s
  # => "2019-12-07 12:00:00 +0900"
```

If one has Chronic present in their project but doesn't want it to interfere with et-orbi, it can be disabled at `parse` call:
```ruby
EtOrbi.parse('tomorrow')
  # => #<EtOrbi::EoTime:0x007ffb5b2a2390
  #      @seconds=1575687600.0,
  #      @zone=#<TZInfo::TimezoneProxy: Asia/Tokyo>,
  #      @time=nil>
EtOrbi.parse('tomorrow', enable_chronic: false)
  # ArgumentError: No time information in "tomorrow"
  #   from /home/jmettraux/w/et-orbi/lib/et-orbi/make.rb:31:in `rescue in parse'
```
or at the et-orbi level:
```ruby
irb(main):007:0> EtOrbi.chronic_enabled = false
  # => false
irb(main):008:0> EtOrbi.chronic_enabled?
  # => false
EtOrbi.parse('tomorrow')
  # ArgumentError: No time information in "tomorrow"
  #   from /home/jmettraux/w/et-orbi/lib/et-orbi/make.rb:31:in `rescue in parse'
```

### Rails?

If Rails is present, `Time.zone` is provided and EtOrbi will use it, unless `ENV['TZ']` is set to a valid timezone name. Setting `ENV['TZ']` to nil can give back precedence to `Time.zone`.

Rails sets its timezone under `config/application.rb`.


## Related projects

### Sister projects

* [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler) - a cron/at/in/every/interval in-process scheduler, in fact, it's the father project to this fugit project
* [fugit](https://github.com/floraison/fugit) - Time tools for flor and the floraison project. Cron parsing and occurrence computing. Timestamps and more.


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

