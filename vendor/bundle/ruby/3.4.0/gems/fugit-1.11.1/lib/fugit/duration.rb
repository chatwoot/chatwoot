# frozen_string_literal: true

module Fugit

  class Duration

    attr_reader :original, :h, :options

    class << self

      def new(s)

        parse(s)
      end

      def parse(s, opts={})

        return s if s.is_a?(self)

        original = s

        s = "#{s}s" if s.is_a?(Numeric)

        return nil unless s.is_a?(String)

        s = s.strip
#p [ original, s ]; Raabro.pp(Parser.parse(s, debug: 3), colours: true)

        h =
          if opts[:iso]
            IsoParser.parse(opts[:stricter] ? s : s.upcase)
          elsif opts[:plain]
            Parser.parse(s)
          else
            Parser.parse(s) || IsoParser.parse(opts[:stricter] ? s : s.upcase)
          end

        h ? self.allocate.send(:init, original, opts, h) : nil
      end

      def do_parse(s, opts={})

        parse(s, opts) ||
        fail(ArgumentError.new("not a duration #{s.inspect}"))
      end

      def to_plain_s(o); do_parse(o).deflate.to_plain_s; end
      def to_iso_s(o); do_parse(o).deflate.to_iso_s; end
      def to_long_s(o, opts={}); do_parse(o).deflate.to_long_s(opts); end

      def common_rewrite_dur(t)

        t
          .subgather(nil)
          .inject({}) { |h, tt|
            v = tt.string; v = v.index('.') ? v.to_f : v.to_i
              # drops ending ("y", "m", ...) by itself
            h[tt.name] = (h[tt.name] || 0) + v
            h }
      end
    end

    KEYS = {
      yea: { a: 'Y', r: 'y', i: 'Y', s: YEAR_S, x: 0, l: 'year' },
      mon: { a: 'M', r: 'M', i: 'M', s: 30 * DAY_S, x: 1, l: 'month' },
      wee: { a: 'W', r: 'w', i: 'W', s: 7 * DAY_S, I: true, l: 'week' },
      day: { a: 'D', r: 'd', i: 'D', s: DAY_S, I: true, l: 'day' },
      hou: { a: 'h', r: 'h', i: 'H', s: 3600, I: true, l: 'hour' },
      min: { a: 'm', r: 'm', i: 'M', s: 60, I: true, l: 'minute' },
      sec: { a: 's', r: 's', i: 'S', s: 1, I: true, l: 'second' } }.freeze

    INFLA_KEYS, NON_INFLA_KEYS = KEYS
      .partition { |k, v| v[:I] }
      .collect(&:freeze)

    def _to_s(key)

      KEYS.inject([ StringIO.new, '+' ]) { |(s, sign), (k, a)|
        v = @h[k]
        next [ s, sign ] unless v
        sign1 = v < 0 ? '-' : '+'
        s << (sign1 != sign ? sign1 : '') << v.abs.to_s << a[key]
        [ s, sign1 ]
      }[0].string
    end; protected :_to_s

    def to_plain_s; _to_s(:a); end
    def to_rufus_s; _to_s(:r); end

    def to_iso_s

      t = false

      s = StringIO.new
      s << 'P'

      KEYS.each_with_index do |(k, a), i|
        v = @h[k]; next unless v
        if i > 3 && t == false
          t = true
          s << 'T'
        end
        s << v.to_s; s << a[:i]
      end

      s.string
    end

    def to_long_s(opts={})

      s = StringIO.new
      adn = [ false, 'no' ].include?(opts[:oxford]) ? ' and ' : ', and '

      a = @h.to_a
      while kv = a.shift
        k, v = kv
        aa = KEYS[k]
        s << v.to_i
        s << ' '; s << aa[:l]; s << 's' if v > 1
        s << (a.size == 1 ? adn : ', ') if a.size > 0
      end

      s.string
    end

    # For now, let's alias to #h
    #
    def to_h; h; end

    def to_rufus_h

      KEYS.inject({}) { |h, (ks, kh)| v = @h[ks]; h[kh[:r].to_sym] = v if v; h }
    end

    # Warning: this is an "approximation", months are 30 days and years are
    # 365 days, ...
    #
    def to_sec

      KEYS.inject(0) { |s, (k, a)| v = @h[k]; next s unless v; s += v * a[:s] }
    end

    def inflate

      params =
        @h.inject({ sec: 0 }) { |h, (k, v)|
          a = KEYS[k]
          if a[:I]
            h[:sec] += (v * a[:s])
          else
            h[k] = v
          end
          h
        }

      self.class.allocate.init(@original, {}, params)
    end

    # Round float seconds to 9 decimals when deflating
    #
    SECOND_ROUND = 9

    def deflate(options={})

      id = inflate
      h = id.h.dup
      s = h.delete(:sec) || 0

      keys = INFLA_KEYS

      mon = options[:month]
      yea = options[:year]
      keys = keys.dup if mon || yea

      if mon
        mon = 30 if mon == true
        mon = "#{mon}d" if mon.is_a?(Integer)
        keys.unshift([ :mon, { s: Fugit::Duration.parse(mon).to_sec } ])
      end
      if yea
        yea = 365 if yea == true
        yea = "#{yea}d" if yea.is_a?(Integer)
        keys.unshift([ :yea, { s: Fugit::Duration.parse(yea).to_sec } ])
      end

      keys[0..-2].each do |k, v|

        vs = v[:s]; next if s < vs

        h[k] = (h[k] || 0) + s.to_i / vs
        s = s % vs
      end

      h[:sec] = s.is_a?(Integer) ? s : s.round(SECOND_ROUND)

      self.class.allocate.init(@original, {}, h)
    end

    def opposite

      params = @h.inject({}) { |h, (k, v)| h[k] = -v; h }

      self.class.allocate.init(nil, {}, params)
    end

    alias -@ opposite

    def add_numeric(n)

      h = @h.dup
      h[:sec] = (h[:sec] || 0) + n.to_i

      self.class.allocate.init(nil,{}, h)
    end

    def add_duration(d)

      params = d.h.inject(@h.dup) { |h, (k, v)| h[k] = (h[k] || 0) + v; h }

      self.class.allocate.init(nil, {}, params)
    end

    def add_to_time(t)

      t = ::EtOrbi.make_time(t)

      INFLA_KEYS.each do |k, a|

        v = @h[k]; next unless v

        t = t + v * a[:s]
      end

      NON_INFLA_KEYS.each do |k, a|

        v = @h[k]; next unless v
        at = [ t.year, t.month, t.day, t.hour, t.min, t.sec ]

        at[a[:x]] += v

        if at[1] > 12
          n, m = at[1] / 12, at[1] % 12
          at[0], at[1] = at[0] + n, m
        elsif at[1] < 1
          n, m = (-at[1]) / 12 + 1, (11+at[1]) % 12 + 1
          at[0], at[1] = at[0] - n, m
        end

        t = ::EtOrbi.make_time(at, t.zone)
      end

      t
    end

    def add(a)

      case a
      when Numeric then add_numeric(a)
      when Fugit::Duration then add_duration(a)
      when String then add_duration(self.class.parse(a))
      when ::Time, ::EtOrbi::EoTime then add_to_time(a)
      else fail ArgumentError.new(
        "cannot add #{a.class} instance to a Fugit::Duration")
      end
    end
    alias + add

    def subtract(a)

      case a
      when Numeric then add_numeric(-a)
      when Fugit::Duration then add_duration(-a)
      when String then add_duration(-self.class.parse(a))
      when ::Time, ::EtOrbi::EoTime then opposite.add_to_time(a)
      else fail ArgumentError.new(
        "cannot subtract #{a.class} instance to a Fugit::Duration")
      end
    end
    alias - subtract

    def ==(o)

      o.is_a?(Fugit::Duration) && o.h == @h
    end
    alias eql? ==

    def hash

      @h.hash
    end

    def next_time(from=::EtOrbi::EoTime.now)

      add(from)
    end

    # Returns a copy of this duration, omitting its seconds.
    #
    def drop_seconds

      h = @h.dup
      h.delete(:sec)
      h[:min] = 0 if h.empty?

      self.class.allocate.init(nil, { literal: true }, h)
    end

    protected

    def init(original, options, h)

      @original = original
      @options = options

      if options[:literal]
        @h = h
      else
        @h = h.reject { |k, v| v == 0 }
        @h[:sec] = 0 if @h.empty?
      end

      self
    end

    module Parser include Raabro

      # piece parsers bottom to top

      def sep(i); rex(nil, i, /([ \t,]+|and)*/i); end

      def yea(i); rex(:yea, i, /(\d+\.\d*|(\d*\.)?\d+) *y(ears?)?/i); end
      def mon(i); rex(:mon, i, /(\d+\.\d*|(\d*\.)?\d+) *(M|months?)/); end
      def wee(i); rex(:wee, i, /(\d+\.\d*|(\d*\.)?\d+) *w(eeks?)?/i); end
      def day(i); rex(:day, i, /(\d+\.\d*|(\d*\.)?\d+) *d(ays?)?/i); end
      def hou(i); rex(:hou, i, /(\d+\.\d*|(\d*\.)?\d+) *h(ours?)?/i); end
      def min(i); rex(:min, i, /(\d+\.\d*|(\d*\.)?\d+) *m(in(ute)?s?)?/); end

      def sec(i); rex(:sec, i, /(\d+\.\d*|(\d*\.)?\d+) *s(ec(ond)?)?s?/i); end
      def sek(i); rex(:sec, i, /(\d+\.\d*|\.\d+|\d+)$/); end

      def elt(i); alt(nil, i, :yea, :mon, :wee, :day, :hou, :min, :sec, :sek); end
      def sign(i); rex(:sign, i, /[-+]?/); end

      def sdur(i); seq(:sdur, i, :sign, '?', :elt, '+'); end

      def dur(i); jseq(:dur, i, :sdur, :sep); end

      # rewrite parsed tree

      def merge(h0, h1)

        sign = h1.delete(:sign) || 1

        h1.inject(h0) { |h, (k, v)| h.merge(k => (h[k] || 0) + sign * v) }
      end

      def rewrite_sdur(t)

        h = Fugit::Duration.common_rewrite_dur(t)

        sign = t.sublookup(:sign)
        sign = (sign && sign.string == '-') ? -1 : 1

        h.merge(sign: sign)
      end

      def rewrite_dur(t)

#Raabro.pp(t, colours: true)
        t.children.inject({}) { |h, ct| merge(h, ct.name ? rewrite(ct) : {}) }
      end
    end

    module IsoParser include Raabro

      # piece parsers bottom to top

      def p(i); rex(nil, i, /P/); end
      def t(i); rex(nil, i, /T/); end

      def yea(i); rex(:yea, i, /-?\d+Y/); end
      def mon(i); rex(:mon, i, /-?\d+M/); end
      def wee(i); rex(:wee, i, /-?\d+W/); end
      def day(i); rex(:day, i, /-?\d+D/); end
      def hou(i); rex(:hou, i, /-?\d+H/); end
      def min(i); rex(:min, i, /-?\d+M/); end
      def sec(i); rex(:sec, i, /-?(\d*\.)?\d+S/); end

      def delt(i); alt(nil, i, :yea, :mon, :wee, :day); end
      def telt(i); alt(nil, i, :hou, :min, :sec); end

      def date(i); rep(nil, i, :delt, 1); end
      def time(i); rep(nil, i, :telt, 1); end
      def t_time(i); seq(nil, i, :t, :time); end

      def dur(i); seq(:dur, i, :p, :date, '?', :t_time, '?'); end

      # rewrite parsed tree

      def rewrite_dur(t); Fugit::Duration.common_rewrite_dur(t); end
    end
  end
end

