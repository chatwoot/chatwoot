
module EtOrbi

  class << self

    def get_tzone(o)

      return o if o.is_a?(::TZInfo::Timezone)
      return nil if o == nil
      return determine_local_tzone if o == :local
      return ::TZInfo::Timezone.get('Zulu') if o == 'Z'
      return o.tzinfo if o.respond_to?(:tzinfo)

      o = to_offset(o) if o.is_a?(Numeric)

      return nil unless o.is_a?(String)

      s = tweak_zone_name(o)

      get_offset_tzone(s) ||
      get_x_offset_tzone(s) ||
      get_tzinfo_tzone(s)
    end

    protected

    # custom timezones, no DST, just an offset, like "+08:00" or "-01:30"
    #
    def get_offset_tzone(str)

      m = str.match(/\A([+-][0-1]?[0-9]):?([0-5][0-9])?\z/) rescue nil
        #
        # On Windows, the real encoding could be something other than UTF-8,
        # and make the match fail
        #
      return nil unless m

      tz = custom_tzs[str]
      return tz if tz

      hr = m[1].to_i
      mn = m[2].to_i

      hr = nil if hr.abs > 11
      hr = nil if mn > 59
      mn = -mn if hr && hr < 0

      hr ?
        custom_tzs[str] = create_offset_tzone(hr * 3600 + mn * 60, str) :
        nil
    end

    if defined?(TZInfo::DataSources::ConstantOffsetDataTimezoneInfo)
      # TZInfo >= 2.0.0

      def create_offset_tzone(utc_off, id)

        off = TZInfo::TimezoneOffset.new(utc_off, 0, id)
        tzi = TZInfo::DataSources::ConstantOffsetDataTimezoneInfo.new(id, off)
        tzi.create_timezone
      end

    else
      # TZInfo < 2.0.0

      def create_offset_tzone(utc_off, id)

        tzi = TZInfo::TransitionDataTimezoneInfo.new(id)
        tzi.offset(id, utc_off, 0, id)
        tzi.create_timezone
      end
    end

    def get_x_offset_tzone(str)

      m = str.match(/\A_..-?[0-1]?\d:?(?:[0-5]\d)?(.+)\z/) rescue nil
        #
        # On Windows, the real encoding could be something other than UTF-8,
        # and make the match fail (as in .get_offset_tzone above)

      m ? ::TZInfo::Timezone.get(m[1]) : nil
    end

    def to_offset(n)

      i = n.to_i
      sn = i < 0 ? '-' : '+'; i = i.abs
      hr = i / 3600; mn = i % 3600; sc = i % 60

      sc > 0 ?
        '%s%02d:%02d:%02d' % [ sn, hr, mn, sc ] :
        '%s%02d:%02d' % [ sn, hr, mn ]
    end

    def get_tzinfo_tzone(name)

      #return ::TZInfo::Timezone.get(name) rescue nil

      loop do
        return ::TZInfo::Timezone.get(name) if ZONES_OLSON.include?(name)
        name = name[0..-2]
        return nil if name.empty?
      end
    end

    def windows_zone_code_x(zone_name)

      a = [ '_' ]
      a.concat(zone_name.split('/')[0, 2].collect { |s| s[0, 1].upcase })
      a << '_' if a.size < 3

      a.join
    end

    def get_local_tzone(t)

      l = Time.local(t.year, t.month, t.day, t.hour, t.min, t.sec, t.usec)

      (t.zone == l.zone) ? determine_local_tzone : nil
    end

    # https://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html
    #
    # If it responds to #time_zone, then return that time zone.
    #
    def get_as_tzone(t)

      t.respond_to?(:time_zone) ? t.time_zone : nil
    end
  end
end

