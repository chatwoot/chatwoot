# frozen_string_literal: true

module Fugit

  # A natural language set of parsers for fugit.
  # Focuses on cron expressions. The rest is better left to Chronic and friends.
  #
  module Nat

    MAX_INPUT_LENGTH = 256

    class << self

      def parse(s, opts={})

        return s if s.is_a?(Fugit::Cron) || s.is_a?(Fugit::Duration)

        return nil unless s.is_a?(String)

        s = s.strip

        if s.length > MAX_INPUT_LENGTH

          fail ArgumentError.new(
            "input too long for a nat string, " +
            "#{s.length} > #{MAX_INPUT_LENGTH}"
          ) if opts[:do_parse]

          return nil
        end

#p s; Raabro.pp(Parser.parse(s, debug: 3), colours: true)
#(p s; Raabro.pp(Parser.parse(s, debug: 1), colours: true)) rescue nil

        if slots = Parser.parse(s)
          slots.to_crons(opts.merge(_s: s))
        else
          nil
        end
      end

      def do_parse(s, opts={})

        parse(s, opts.merge(do_parse: true)) ||
        fail(ArgumentError.new("could not parse a nat #{s.inspect}"))
      end
    end

    module Parser include Raabro

      one_to_nine =
        %w[ one two three four five six seven eight nine ]
      sixties =
        %w[ zero ] + one_to_nine +
        %w[ ten eleven twelve thirteen fourteen fifteen sixteen seventeen
            eighteen nineteen ] +
          %w[ twenty thirty fourty fifty ]
            .collect { |a|
              ([ nil ] + one_to_nine)
                .collect { |b| [ a, b ].compact.join('-') } }
            .flatten

      NHOURS = sixties[0, 13]
        .each_with_index
        .inject({}) { |h, (n, i)| h[n] = i; h }
        .merge!(
          'midnight' => 0, 'oh' => 0, 'noon' => 12)
        .freeze
      NMINUTES = sixties
        .each_with_index
        .inject({}) { |h, (n, i)| h[n] = i; h }
        .merge!(
          "o'clock" => 0, 'hundred' => 0)
        .freeze

      WEEKDAYS = (
        Fugit::Cron::Parser::WEEKDAYS +
        Fugit::Cron::Parser::WEEKDS).freeze

      POINTS = %w[
        minutes? mins? seconds? secs? hours? hou h ].freeze

      INTERVALS = %w[
        seconds? minutes? hours? days? months?
        sec min
        s m h d M ].freeze

      oh = {
        '1st' => 1, '2nd' => 2, '3rd' => 3, '21st' => 21, '22nd' => 22,
        '23rd' => 23, '31st' => 31,
        'last' => 'L' }
      (4..30)
        .each { |i| oh["#{i}th"] = i.to_i }
      %w[
        first second third fourth fifth sixth seventh eighth ninth tenth
        eleventh twelfth thirteenth fourteenth fifteenth sixteenth seventeenth
        eighteenth nineteenth twentieth twenty-first twenty-second twenty-third
        twenty-fourth twenty-fifth twenty-sixth twenty-seventh twenty-eighth
        twenty-ninth thirtieth thirty-first ]
          .each_with_index { |e, i| oh[e] = i + 1 }
      OMONTHDAYS = oh.freeze

      OMONTHDAY_REX = /#{OMONTHDAYS.keys.join('|')}/i.freeze
      MONTHDAY_REX = /3[0-1]|[0-2]?[0-9]/.freeze
      WEEKDAY_REX = /(#{WEEKDAYS.join('|')})(?=($|[-, \t]))/i.freeze
        # prevent "mon" from eating "monday"
      NAMED_M_REX = /#{NMINUTES.keys.join('|')}/i.freeze
      NAMED_H_REX = /#{NHOURS.keys.join('|')}/i.freeze
      POINT_REX = /(#{POINTS.join('|')})[ \t]+/i.freeze
      INTERVAL_REX = /[ \t]*(#{INTERVALS.join('|')})/.freeze

      #
      # parsers bottom to top #################################################

      def _every(i); rex(nil, i, /[ \t]*every[ \t]+/i); end
      def _from(i); rex(nil, i, /[ \t]*from[ \t]+/i); end
      def _at(i); rex(nil, i, /[ \t]*at[ \t]+/i); end
      def _on(i); rex(nil, i, /[ \t]*on[ \t]+/i); end
      def _to(i); rex(nil, i, /[ \t]*to[ \t]+/i); end

      def _and(i); rex(nil, i, /[ \t]*and[ \t]+/i); end
      def _and_or_or(i); rex(nil, i, /[ \t]*(and|or)[ \t]+/i); end
      def _in_or_on(i); rex(nil, i, /(in|on)[ \t]+/i); end

      def _and_or_or_or_comma(i)
        rex(nil, i, /[ \t]*(,[ \t]*)?((and|or)[ \t]+|,[ \t]*)/i); end

      def _to_or_dash(i);
        rex(nil, i, /[ \t]*-[ \t]*|[ \t]+(to|through)[ \t]+/i); end

      def _day_s(i); rex(nil, i, /[ \t]*days?[ \t]+/i); end
      def _the(i); rex(nil, i, /[ \t]*the[ \t]+/i); end

      def _space(i); rex(nil, i, /[ \t]+/); end
      def _sep(i); rex(nil, i, /([ \t]+|[ \t]*,[ \t]*)/); end

      def count(i); rex(:count, i, /\d+/); end

      def omonthday(i)
        rex(:omonthday, i, OMONTHDAY_REX)
      end
      def monthday(i)
        rex(:monthday, i, MONTHDAY_REX)
      end
      def weekday(i)
        rex(:weekday, i, WEEKDAY_REX)
      end

      def omonthdays(i); jseq(nil, i, :omonthday, :_and_or_or_or_comma); end
      def monthdays(i); jseq(nil, i, :monthday, :_and_or_or_or_comma); end

      def weekdays(i); jseq(:weekdays, i, :weekday, :_and_or_or_or_comma); end

      def on_the(i); seq(nil, i, :_the, :omonthdays); end

      def _minute(i); rex(nil, i, /[ \t]*minute[ \t]+/i) end

      def _dmin(i)
        rex(:dmin, i, /[0-5]?[0-9]/)
      end
      def and_dmin(i)
        seq(nil, i, :_and_or_or_or_comma, :_minute, '?', :_dmin)
      end

      def on_minutes(i)
        seq(:on_minutes, i, :_minute, :_dmin, :and_dmin, '*')
      end

      def on_thex(i);
        rex(:on_thex, i, /[ \t]*the[ \t]+(hour|minute)[ \t]*/i);
      end

      def on_thes(i); jseq(:on_thes, i, :on_the, :_and_or_or_or_comma); end
      def on_days(i); seq(:on_days, i, :_day_s, :monthdays); end
      def on_weekdays(i); ren(:on_weekdays, i, :weekdays); end

      def on_object(i)
        alt(nil, i, :on_days, :on_weekdays, :on_minutes, :on_thes, :on_thex)
      end
      def on_objects(i)
        jseq(nil, i, :on_object, :_and)
      end

        #'every month on day 2 at 10:00' => '0 10 2 * *',
        #'every month on day 2 and 5 at 10:00' => '0 10 2,5 * *',
        #'every month on days 1,15 at 10:00' => '0 10 1,15 * *',
        #
        #'every week on monday 18:23' => '23 18 * * 1',
        #
        # every month on the 1st
        #
      def on(i)
        seq(:on, i, :_on, :on_objects)
      end

      def city_tz(i)
        rex(nil, i, /[A-Z][a-zA-Z0-9+\-]+(\/[A-Z][a-zA-Z0-9+\-_]+){0,2}/)
      end
      def named_tz(i)
        rex(nil, i, /Z|UTC/)
      end
      def delta_tz(i)
        rex(nil, i, /[-+]([01][0-9]|2[0-4])(:?(00|15|30|45))?/)
      end
      def tz(i)
        alt(:tz, i, :city_tz, :named_tz, :delta_tz)
      end
      def tzone(i)
        seq(nil, i, :_in_or_on, '?', :tz)
      end

      def ampm(i)
        rex(:ampm, i, /[ \t]*(am|pm|noon|midday|midnight)/i)
      end
      def dark(i)
        rex(:dark, i, /[ \t]*dark/i)
      end

      def digital_h(i)
        rex(:digital_h, i, /(2[0-4]|[0-1]?[0-9]):([0-5][0-9])/i)
      end
      def digital_hour(i)
        seq(:digital_hour, i, :digital_h, :ampm, '?')
      end

      def simple_h(i)
         rex(:simple_h, i, /#{(0..24).to_a.reverse.join('|')}/)
      end
      def simple_hour(i)
        seq(:simple_hour, i, :simple_h, :ampm, '?')
      end

      def named_m(i)
        rex(:named_m, i, NAMED_M_REX)
      end
      def named_min(i)
        seq(nil, i, :_space, :named_m)
      end

      def named_h(i)
        rex(:named_h, i, NAMED_H_REX)
      end
      def named_hour(i)
        seq(:named_hour, i, :named_h, :dark, '?', :named_min, '?', :ampm, '?')
      end

      def _point(i); rex(:point, i, POINT_REX); end

      def counts(i)
        jseq(nil, i, :count, :_and_or_or_or_comma)
      end

      def at_p(i)
        seq(:at_p, i, :_point, :counts)
      end
      def at_point(i)
        jseq(nil, i, :at_p, :_and_or_or)
      end

        # at five
        # at five pm
        # at five o'clock
        # at 16:30
        # at noon
        # at 18:00 UTC <-- ...tz
      def at_object(i)
        alt(nil, i, :named_hour, :digital_hour, :simple_hour, :at_point)
      end
      def at_objects(i)
        jseq(nil, i, :at_object, :_and_or_or_or_comma)
      end

      def at(i)
        seq(:at, i, :_at, '?', :at_objects)
      end

      def interval(i)
        rex(:interval, i, INTERVAL_REX)
      end

        # every day
        # every 1 minute
      def every_interval(i)
        seq(:every_interval, i, :count, '?', :interval)
      end

      def every_single_interval(i)
        rex(:every_single_interval, i, /(1[ \t]+)?(week|year)/)
      end

      def to_weekday(i)
        seq(:to_weekday, i, :weekday, :_to_or_dash, :weekday)
      end

      def weekday_range(i)
        alt(nil, i, :to_weekday, :weekdays)
      end

      def to_omonthday(i)
        seq(:to_omonthday, i,
          :_the, '?', :omonthday, :_to, :_the, '?', :omonthday)
      end

      def to_hour(i)
        seq(:to_hour, i, :at_object, :_to, :at_object)
      end

      def from_object(i)
        alt(nil, i, :to_weekday, :to_omonthday, :to_hour)
      end
      def from_objects(i)
        jseq(nil, i, :from_object, :_and_or_or)
      end
      def from(i)
        seq(nil, i, :_from, '?', :from_objects)
      end

        # every monday
        # every Fri-Sun
        # every Monday and Tuesday
      def every_weekday(i)
        jseq(nil, i, :weekday_range, :_and_or_or)
      end

      def otm(i)
        rex(nil, i, /[ \t]+of the month/)
      end

        # every 1st of the month
        # every first of the month
        # Every 2nd of the month
        # Every second of the month
        # every 15th of the month
      def every_of_the_month(i)
        seq(nil, i, :omonthdays, :otm)
      end

      def every_named(i)
        rex(:every_named, i, /weekday/i)
      end

      def every_object(i)
        alt(
          nil, i,
          :every_weekday, :every_of_the_month,
          :every_interval, :every_named, :every_single_interval)
      end
      def every_objects(i)
        jseq(nil, i, :every_object, :_and_or_or)
      end

      def every(i)
        seq(:every, i, :_every, :every_objects)
      end

      def nat_elt(i)
        alt(nil, i, :every, :from, :at, :tzone, :on)
      end
      def nat(i)
        jseq(:nat, i, :nat_elt, :_sep)
      end

      #
      # rewrite parsed tree ###################################################

      def slot(key, data0, data1=nil, opts=nil)
        Slot.new(key, data0, data1, opts)
      end

      def _rewrite_subs(t, key=nil)
        t.subgather(key).collect { |ct| rewrite(ct) }
      end
      def _rewrite_sub(t, key=nil)
        st = t.sublookup(key)
        st ? rewrite(st) : nil
      end

      def rewrite_dmin(t)
        t.strinp
      end

      def rewrite_on_minutes(t)
#Raabro.pp(t, colours: true)
        mins = t.subgather(:dmin).collect(&:strinp)
        #slot(:m, mins.join(','))
        slot(:hm, '*', mins.join(','), strong: 1)
      end

      def rewrite_on_thex(t)
        case s = t.string
        #when /hour/i then slot(:h, 0)
        #else slot(:m, '*')
        when /hour/i then slot(:hm, 0, '*', strong: 0)
        else slot(:hm, '*', '*', strong: 1)
        end
      end

      def rewrite_on_thes(t)
        _rewrite_subs(t, :omonthday)
      end
      def rewrite_on_days(t)
        _rewrite_subs(t, :monthday)
      end

      def rewrite_on(t)
        _rewrite_subs(t)
      end

      def rewrite_monthday(t)
        slot(:monthday, t.string.to_i)
      end

      def rewrite_omonthday(t)
        slot(:monthday, OMONTHDAYS[t.string.downcase])
      end

      def rewrite_at_p(t)
        pt = t.sublookup(:point).strinpd
        pt = pt.start_with?('mon') ? 'M' : pt[0, 1]
        pts = t.subgather(:count).collect { |e| e.string.to_i }
#p [ pt, pts ]
        case pt
        #when 'm' then slot(:m, pts)
        when 'm' then slot(:hm, '*', pts, strong: 1)
        when 's' then slot(:second, pts)
        else slot(pt.to_sym, pts)
        end
      end

      def rewrite_every_single_interval(t)
        case t.string
        when /year/i then [ slot(:month, 1, :weak), slot(:monthday, 1, :weak) ]
        #when /week/i then xxx...
        else slot(:weekday, 0, :weak)
        end
      end

      def rewrite_every_interval(t)

#Raabro.pp(t, colours: true)
        ci = t.subgather(nil).collect(&:string)
        i = ci.pop.strip[0, 3]
        c = (ci.pop || '1').strip
        i = (i == 'M' || i.downcase == 'mon') ? 'M' : i[0, 1].downcase
        cc = c == '1' ? '*' : "*/#{c}"

        case i
        when 'M' then slot(:month, cc)
        when 'd' then slot(:monthday, cc, :weak)
        #when 'h' then slot(:hm, cc, 0, weak: :minute)
        when 'h' then slot(:hm, cc, 0, weak: 1)
        when 'm' then slot(:hm, '*', cc, strong: 1)
        when 's' then slot(:second, cc)
        else {}
        end
      end

      def rewrite_every_named(t)

        case s = t.string
        when /weekday/i then slot(:weekday, '1-5', :weak)
        when /week/i then slot(:weekday, '0', :weak)
        else fail "cannot rewrite #{s.inspect}"
        end
      end

      def rewrite_tz(t)

        slot(:tz, t.string)
      end

      def rewrite_weekday(t)

        Fugit::Cron::Parser::WEEKDS.index(t.string[0, 3].downcase)
      end

      def rewrite_weekdays(t)

#Raabro.pp(t, colours: true)
        slot(:weekday, _rewrite_subs(t, :weekday))
      end
      alias rewrite_on_weekdays rewrite_weekdays

      def rewrite_to_weekday(t)

        wd0, wd1 = _rewrite_subs(t, :weekday)
        #wd1 = 7 if wd1 == 0
        slot(:weekday, "#{wd0}-#{wd1}")
      end

      def rewrite_to_omonthday(t)
        md0, md1 = _rewrite_subs(t, :omonthday).collect(&:_data0)
        slot(:monthday, "#{md0}-#{md1}")
      end

      # Try to follow https://en.wikipedia.org/wiki/12-hour_clock#Confusion_at_noon_and_midnight
      #
      def adjust_h(h, m, ap)

        if ap == 'midnight' && h == 12
          24
        elsif ap == 'pm' && h < 12 # post meridian
          h + 12
        elsif ap == 'am' && h == 12 # ante meridian
          0
        else
          h
        end
      end

      def rewrite_digital_hour(t)

        h, m = t.sublookup(:digital_h).strinpd.split(':').collect(&:to_i)
        ap = t.sublookup(:ampm)
        h, m = adjust_h(h, m, ap && ap.strinpd), m

        slot(:hm, h, m)
      end

      def rewrite_simple_hour(t)

        h, ap = t.subgather(nil).collect(&:strinpd)
        h = adjust_h(h.to_i, 0, ap)

        slot(:hm, h, 0)
      end

      def rewrite_named_hour(t)

        ht = t.sublookup(:named_h)
        mt = t.sublookup(:named_m)
        apt = t.sublookup(:ampm)

        h = ht.strinp
        m = mt ? mt.strinp : 0
        h = NHOURS[h]
        m = NMINUTES[m] || m

        h = adjust_h(h, m, apt && apt.strinpd)

        slot(:hm, h, m)
      end

      def rewrite_to_hour(t)
#Raabro.pp(t, colours: true)
        ht0, ht1 = t.subgather(nil)
        h0, h1 = rewrite(ht0), rewrite(ht1)
        fail ArgumentError.new(
          "cannot deal with #{ht0.strinp} to #{ht1.strinp}, minutes diverge"
        ) if h0.data1 != h1.data1
        slot(:hm, "#{h0._data0}-#{h1._data0}", 0, strong: 0)
      end

      def rewrite_at(t)
        _rewrite_subs(t)
      end

      def rewrite_every(t)
        _rewrite_sub(t)
      end

      def rewrite_nat(t)
#Raabro.pp(t, colours: true)
        Fugit::Nat::SlotGroup.new(_rewrite_subs(t).flatten)
      end
    end

    class Slot
      attr_reader :key
      attr_accessor :_data0, :_data1
      def initialize(key, d0, d1=nil, opts=nil)
        d1, opts = d1.is_a?(Symbol) ? [ nil, d1 ] : [ d1, opts ]
        @key, @_data0, @_data1 = key, d0, d1
        @opts = (opts.is_a?(Symbol) ? { opts => true } : opts) || {}
      end
      def data0; @data0 ||= Array(@_data0); end
      def data1; @data1 ||= Array(@_data1); end
      def weak; @opts[:weak]; end
      def strong; @opts[:strong]; end
      def graded?; weak || strong; end
      def append(slot)
        @_data0, @_data1 = conflate(0, slot), conflate(1, slot)
        @opts.clear
        self
      end
      def inspect
        a = [ @key, @_data0 ]
        a << @_data1 if @_data1 != nil
        a << @opts if @opts && @opts.keys.any?
        "(slot #{a.collect(&:inspect).join(' ')})"
      end
      def a; [ data0, data1 ]; end
      protected
      def to_a(x)
        return [] if x == '*'
        Array(x)
      end
      def conflate(index, slot)
        a, b = index == 0 ? [ @_data0, slot._data0 ] : [ @_data1, slot._data1 ]
        return a if b == nil
        return b if a == nil
        if ra = (index == 0 && slot.strong == 1 && hour_range)
          h0, h1 = ra[0], ra[1] - 1; return h0 == h1 ? h0 : "#{h0}-#{h1}"
        elsif rb = (index == 0 && strong == 1 && slot.hour_range)
          h0, h1 = rb[0], rb[1] - 1; return h0 == h1 ? h0 : "#{h0}-#{h1}"
        end
        return a if strong == index || strong == true
        return b if slot.strong == index || slot.strong == true
        return a if slot.weak == index || slot.weak == true
        return b if weak == index || weak == true
        return [ '*' ] if a == '*' && b == '*'
        to_a(a).concat(to_a(b))
      end
      def hour_range
        m = (key == :hm && @_data1 == 0 && @_data0.match(/\A(\d+)-(\d+)\z/))
        m ? [ m[1].to_i, m[2].to_i ] : nil
      end
    end

    class SlotGroup

      def initialize(slots)

#puts "SlotGroup.new " + slots.inspect
        @slots = {}
        @hms = []

        slots.each do |s|
          if s.key == :hm
            #ls = @hms.last; @hms.pop if ls && ls.key == :hm && ls.weak == true
            @hms << s
          elsif hs = @slots[s.key]
            hs.append(s)
          else
            @slots[s.key] = s
          end
        end

        if @slots[:monthday] || @slots[:weekday]
          @hms << make_slot(:hm, 0, 0) if @hms.empty?
        elsif @slots[:month]
          @hms << make_slot(:hm, 0, 0) if @hms.empty?
          @slots[:monthday] ||= make_slot(:monthday, 1)
        end
      end

      def to_crons(opts)

        multi = opts.has_key?(:multi) ? opts[:multi] : false

        hms = determine_hms

        if multi == :fail && hms.count > 1
          fail(ArgumentError.new(
            "multiple crons in #{opts[:_s].inspect} - #{@slots.inspect}"))
        elsif multi == true
          hms.collect { |hm| parse_cron(hm, opts) }
        else
          parse_cron(hms.first, opts)
        end
      end

      protected

      def make_slot(key, data0, data1=nil)

        Fugit::Nat::Slot.new(key, data0, data1)
      end

      def determine_hms

        return [ [ [ '*' ], [ '*' ] ] ] if @hms.empty?

        hms = @hms.dup
          #
        while ig = (hms.count > 1 && hms.index { |hm| hm.graded? }) do
          sg = hms[ig]
          so = hms.delete_at(ig == 0 ? 1 : ig - 1)
          sg.append(so)
        end

        hms
          .collect(&:a)
          .inject({}) { |r, hm|
            hm[1].each { |m| (r[m] ||= []).concat(hm[0]) }
            r }
          .inject({}) { |r, (m, hs)|
            (r[hs.sort] ||= []) << m
            r }
          .to_a
      end

      def parse_cron(hm, opts)

        a = [
          slot(:second, '0'),
          hm[1],
          hm[0],
          slot(:monthday, '*'),
          slot(:month, '*'),
          slot(:weekday, '*') ]
        tz = @slots[:tz]
        a << tz.data0 if tz
        a.shift if a.first == [ '0' ]

        letters_last = lambda { |x| x.is_a?(Numeric) ? x : 999_999 }

        s = a
          .collect { |e|
            e.uniq.sort_by(&letters_last).collect(&:to_s).join(',') }
          .join(' ')

        c = Fugit::Cron.parse(s)

        if opts[:strict]
          restrict(a, c)
        else
          c
        end
      end

      # Return nil if the cron is "not strict"
      #
      # For example, "0 0/17 * * *" (gh-86) is a perfectly valid
      # cron string, but makes not much sense when derived via `.parse_nat`
      # from "every 17 hours".
      #
      # It happens here because it's nat being strict, not cron.
      #
      def restrict(a, cron)

        if m = ((a[1] && a[1][0]) || '').match(/^(\d+|\*)\/(\d+)$/)
#p m
           sla = m[1].to_i
          return nil unless [ 1, 2, 3, 4, 5, 6, 8, 12 ].include?(sla)
        end

        cron
      end

      def slot(key, default)
        s = @slots[key]
        s ? s.data0 : [ default ]
      end
    end
  end
end

