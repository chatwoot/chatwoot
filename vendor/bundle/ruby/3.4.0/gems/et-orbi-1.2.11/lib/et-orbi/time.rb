
module EtOrbi

  # Our EoTime class (which quacks like a ::Time).
  #
  # An EoTime instance should respond to most of the methods ::Time instances
  # respond to. If a method is missing, feel free to open an issue to
  # ask (politely) for it. If it makes sense, it'll get added, else
  # a workaround will get suggested.
  # The immediate workaround is to call #to_t on the EoTime instance to get
  # equivalent ::Time instance in the local, current, timezone.
  #
  class EoTime

    #
    # class methods

    class << self

      def now(zone=nil)

        EtOrbi.now(zone)
      end

      def parse(str, opts={})

        EtOrbi.parse(str, opts)
      end

      def get_tzone(o)

        EtOrbi.get_tzone(o)
      end

      def local_tzone

        EtOrbi.determine_local_tzone
      end

      def platform_info

        EtOrbi.platform_info
      end

      def make(o)

        EtOrbi.make_time(o)
      end

      def utc(*a)

        EtOrbi.send(:make_from_array, a, EtOrbi.get_tzone('UTC'))
      end

      def local(*a)

        EtOrbi.send(:make_from_array, a, local_tzone)
      end
    end

    #
    # instance methods

    attr_reader :seconds
    attr_reader :zone

    def initialize(s, zone)

      z = zone
      z = nil if zone.is_a?(String) && zone.strip == ''
        #
        # happens with JRuby (and offset tzones like +04:00)
        #
        # $ jruby -r time -e "p Time.parse('2012-1-1 12:00 +04:00').zone"
        # # => ""
        # ruby -r time -e "p Time.parse('2012-1-1 12:00 +04:00').zone"
        # # => nil

      @seconds = s.to_f
      @zone = self.class.get_tzone(z || :local)

      fail ArgumentError.new(
        "Cannot determine timezone from #{zone.inspect}" +
        "\n#{EtOrbi.render_nozone_time(@seconds)}" +
        "\n#{EtOrbi.platform_info.sub(',debian:', ",\ndebian:")}" +
        "\nTry setting `ENV['TZ'] = 'Continent/City'` in your script " +
        "(see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)" +
        (defined?(TZInfo::Data) ? '' : "\nand adding gem 'tzinfo-data'")
      ) unless @zone

      touch
    end

    # Nullify the "caches" used by #to_time, #rweek, and others
    #
    def touch

      @time = nil
      @rday = nil
      @rweek = nil
    end

    def seconds=(f)

      @seconds = f

      touch

      f
    end

    def zone=(z)


      @zone = self.class.get_tzone(zone || :current)

      touch

      @zone
    end

    # Returns true if this EoTime instance corresponds to 2 different UTC
    # times.
    # It happens when transitioning from DST to winter time.
    #
    # https://www.timeanddate.com/time/change/usa/new-york?year=2018
    #
    def ambiguous?

      @zone.local_to_utc(@zone.utc_to_local(utc))

      false

    rescue TZInfo::AmbiguousTime

      true
    end

    # Returns this ::EtOrbi::EoTime as a ::Time instance
    # in the current UTC timezone.
    #
    def utc

      Time.utc(1970) + @seconds
    end

    # Returns true if this ::EtOrbi::EoTime instance timezone is UTC.
    # Returns false else.
    #
    def utc?

      %w[ gmt utc zulu etc/gmt etc/utc ].include?(
        @zone.canonical_identifier.downcase)
    end

    alias getutc utc
    alias getgm utc
    alias to_utc_time utc

    def to_f

      @seconds
    end

    def to_i

      @seconds.to_i
    end

    def strftime(format)

      format = format.gsub(/%(\/?Z|:{0,2}z)/) { |f| strfz(f) }

      to_time.strftime(format)
    end

    # Returns this ::EtOrbi::EoTime as a ::Time instance
    # in the current timezone.
    #
    # Has a #to_t alias.
    #
    def to_local_time

      Time.at(@seconds)
    end

    alias to_t to_local_time

    def is_dst?

      @zone.period_for_utc(utc).std_offset != 0
    end
    alias isdst is_dst?

    def to_debug_s

      uo = self.utc_offset
      uos = uo < 0 ? '-' : '+'
      uo = uo.abs
      uoh, uom = [ uo / 3600, uo % 3600 ]

      [
        'ot',
        self.strftime('%Y-%m-%d %H:%M:%S'),
        "%s%02d:%02d" % [ uos, uoh, uom ],
        "dst:#{self.isdst}"
      ].join(' ')
    end

    def utc_offset

      @zone.period_for_utc(utc).utc_total_offset
    end

    %w[
      year month day wday yday hour min sec usec asctime
    ].each do |m|
      define_method(m) { to_time.send(m) }
    end

    def ==(o)

      if o.is_a?(EoTime)
        o.seconds == @seconds &&
        (o.zone == @zone || o.zone.current_period == @zone.current_period)
      elsif o.is_a?(::Time)
        (to_f * 1000).to_i == (o.to_f * 1000).to_i
      else
        false
      end
    end

    # Nota Bene:
    #
    # Unlike ==, the equal? method should never be overridden by subclasses
    # as it is used to determine object identity (that is, a.equal?(b) if and
    # only if a is the same object as b)
    #
    # The eql? method returns true if obj and other refer to the same hash key.
    # This is used by Hash to test members for equality.

    def >(o); @seconds > _to_f(o); end
    def >=(o); @seconds >= _to_f(o); end
    def <(o); @seconds < _to_f(o); end
    def <=(o); @seconds <= _to_f(o); end
    def <=>(o); @seconds <=> _to_f(o); end

    def add(t); @seconds += t.to_f; touch; self; end
    def subtract(t); @seconds -= t.to_f; touch; self; end

    def +(t); inc(t, 1); end
    def -(t); inc(t, -1); end

    DAY_S = 24 * 3600
    WEEK_S = 7 * DAY_S

    def monthdays

      date = to_time

      pos = 1
      d = self.dup

      loop do
        d.add(-WEEK_S)
        break if d.month != date.month
        pos = pos + 1
      end

      neg = -1
      d = self.dup

      loop do
        d.add(WEEK_S)
        break if d.month != date.month
        neg = neg - 1
      end

      [ "#{date.wday}##{pos}", "#{date.wday}##{neg}" ]
    end

    def to_s

      strftime('%Y-%m-%d %H:%M:%S %z')
    end

    def to_zs

      strftime('%Y-%m-%d %H:%M:%S %/Z')
    end

    def iso8601(fraction_digits=0)

      s = (fraction_digits || 0) > 0 ? ".%#{fraction_digits}N" : ''
      strftime("%Y-%m-%dT%H:%M:%S#{s}%:z")
    end

    # Debug current time by showing local time / delta / utc time
    # for example: "0120-7(0820)"
    #
    def to_utc_comparison_s

      per = @zone.period_for_utc(utc)
      off = per.utc_total_offset

      off = off / 3600
      off = off >= 0 ? "+#{off}" : off.to_s

      strftime('%H%M') + off + utc.strftime('(%H%M)')
    end

    def to_time_s

      strftime('%H:%M:%S.%6N')
    end

    def inc(t, dir=1)

      r =
        case t
        when Numeric
          nt = self.dup
          nt.seconds += dir * t.to_f
          nt
        when ::Time, ::EtOrbi::EoTime
          fail ArgumentError.new(
            "Cannot add #{t.class} to EoTime") if dir > 0
          @seconds + dir * t.to_f
        else
          fail ArgumentError.new(
            "Cannot call add or subtract #{t.class} to EoTime instance")
        end

      touch

      r
    end

    def localtime(zone=nil)

      EoTime.new(self.to_f, zone)
    end

    alias translate localtime
    alias in_time_zone localtime

    def wday_in_month

      [ count_weeks(EtOrbi.make_time(strftime('%F 12:00:00 %/Z')), -1),
        - count_weeks(EtOrbi.make_time(strftime('%F 12:00:00 %/Z')) , 1) ]
    end

    # "reference week", used in fugit for cron modulo notation
    #
    def rweek

      @rweek ||=
        begin
          ref = EtOrbi.make_time('2019-01-01 12:00:00', @zone)
          noon = EtOrbi.make_time(strftime('%F 12:00:00'), @zone)
          ((noon - ref) / WEEK_S).floor + 1
        end
    end

    # "reference week", used in fugit for cron modulo notation
    #
    def rday

      @rday ||=
        begin
          ref = EtOrbi.make_time('2019-01-01 12:00:00', @zone)
          noon = EtOrbi.make_time(strftime('%F 12:00:00'), @zone)
          ((noon - ref) / DAY_S).floor + 1
        end
    end

    def reach(points)

      t = EoTime.new(self.to_f, @zone)
      step = 1

      s = points[:second] || points[:sec] || points[:s]
      m = points[:minute] || points[:min] || points[:m]
      h = points[:hour] || points[:hou] || points[:h]

      fail ArgumentError.new("missing :second, :minute, and :hour") \
        unless s || m || h

      if !s && !m
        step = 60 * 60
        t -= t.sec
        t -= t.min * 60
      elsif !s
        step = 60
        t -= t.sec
      end

      loop do
        t += step
        next if s && t.sec != s
        next if m && t.min != m
        next if h && t.hour != h
        break
      end

      t
    end

    def clone

      EtOrbi::EoTime.new(@seconds, @zone)
    end

    protected

    # Returns a Ruby Time instance.
    #
    # Warning: the timezone of that Time instance will be UTC when used with
    # TZInfo < 2.0.0.
    #
    def to_time

      @time ||= @zone.utc_to_local(utc)
    end

    def count_weeks(start, dir)

      c = 0
      t = start

      until t.month != self.month
        c += 1
        t += dir * (7 * 24 * 3600)
      end

      c
    end

    def strfz(code)

      return @zone.name if code == '%/Z'

      per = @zone.period_for_utc(utc)

      return per.abbreviation.to_s if code == '%Z'

      off = per.utc_total_offset
        #
      sn = off < 0 ? '-' : '+'; off = off.abs
      hr = off / 3600
      mn = (off % 3600) / 60
      sc = 0

      if @zone.name == 'UTC'
        'Z' # align on Ruby ::Time#iso8601
      elsif code == '%z'
        '%s%02d%02d' % [ sn, hr, mn ]
      elsif code == '%:z'
        '%s%02d:%02d' % [ sn, hr, mn ]
      else
        '%s%02d:%02d:%02d' % [ sn, hr, mn, sc ]
      end
    end

    def _to_f(o)

      fail ArgumentError(
        "Comparison of EoTime with #{o.inspect} failed"
      ) unless o.respond_to?(:to_f)

      o.to_f
    end
  end
end

