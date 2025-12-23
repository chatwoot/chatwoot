
module EtOrbi

  class << self

    ZONES_ISO8601_REX =
      %r{
        (?<=:\d\d)\s*
        (?:
          [-+]
          (?:[0-1][0-9]|2[0-4])
          (?:(?::)?(?:[0-5][0-9]|60))?
          (?![-+])
            |Z
        )
      }x.freeze

    # https://en.wikipedia.org/wiki/ISO_8601
    # Postel's law applies
    #
    def list_iso8601_zones(s)

      s.scan(ZONES_ISO8601_REX).collect(&:strip)
    end

    ZONES_OLSON = (
      ::TZInfo::Timezone.all
        .collect { |z| z.name }.sort +
      (0..12)
        .collect { |i| [ "UTC-#{i}", "UTC+#{i}" ] })
          .flatten
          .sort_by(&:size)
          .reverse

    def extract_zone(str)

      s = str.dup

      zs = ZONES_OLSON
        .inject([]) { |a, z|
          i = s.index(z); next a unless i
          a << z
          s[i, z.length] = ''
          a }

      s.gsub!(ZONES_ISO8601_REX) { |m| zs << m.strip; '' } #if zs.empty?

      zs = zs.sort_by { |z| str.index(z) }

      [ s.strip, zs.last ]
    end

    def determine_local_tzone

      # ENV has the priority

      etz = ENV['TZ']

      tz = etz && get_tzone(etz)
      return tz if tz

      # then Rails/ActiveSupport has the priority

      if Time.respond_to?(:zone) && Time.zone.respond_to?(:tzinfo)
        tz = Time.zone.tzinfo
        return tz if tz
      end

      # then the operating system is queried

      tz = ::TZInfo::Timezone.get(os_tz) rescue nil
      return tz if tz

      # then Ruby's time zone abbs are looked at CST, JST, CEST, ... :-(

      tzs = determine_local_tzones
      tz = (etz && tzs.find { |z| z.name == etz }) || tzs.first
      return tz if tz

      # then, fall back to GMT offest :-(

      n = Time.now

      get_tzone(n.zone) ||
      get_tzone(n.strftime('%Z%z'))
    end
    alias zone determine_local_tzone

    attr_accessor :_os_zone # test tool

    def os_tz

      return (@_os_zone == '' ? nil : @_os_zone) \
        if defined?(@_os_zone) && @_os_zone

      @os_tz ||= (debian_tz || centos_tz || osx_tz)
    end

    #
    # system tz determination

    def debian_tz

      path = '/etc/timezone'

      File.exist?(path) ? File.read(path).strip : nil
    rescue; nil; end

    def centos_tz

      path = '/etc/sysconfig/clock'

      File.open(path, 'rb') do |f|
        until f.eof?
          if m = f.readline.match(/ZONE="([^"]+)"/); return m[1]; end
        end
      end if File.exist?(path)

      nil
    rescue; nil; end

    def osx_tz

      path = '/etc/localtime'

      File.symlink?(path) ?
        File.readlink(path).split('/')[4..-1].join('/') :
        nil
    rescue; nil; end

    def gather_tzs

      { :debian => debian_tz, :centos => centos_tz, :osx => osx_tz }
    end

    # Semi-helpful, since it requires the current time
    #
    def windows_zone_name(zone_name, time)

      twin = Time.utc(time.year, 1, 1) # winter
      tsum = Time.utc(time.year, 7, 1) # summer

      tz = ::TZInfo::Timezone.get(zone_name)
      tzo = tz.period_for_local(time).utc_total_offset
      tzop = tzo < 0 ? nil : '-'; tzo = tzo.abs
      tzoh = tzo / 3600
      tzos = tzo % 3600
      tzos = tzos == 0 ? nil : ':%02d' % (tzos / 60)

      abbs = [
        tz.period_for_utc(twin).abbreviation.to_s,
        tz.period_for_utc(tsum).abbreviation.to_s ]
          .uniq

      if abbs[0].match(/\A[A-Z]/)
        [ abbs[0], tzop, tzoh, tzos, abbs[1] ]
          .compact.join
      else
        [ windows_zone_code_x(zone_name), tzop, tzoh, tzos || ':00', zone_name ]
          .collect(&:to_s).join
      end
    end

    def tweak_zone_name(name)

      return name unless (name.match(/./) rescue nil)
        # to prevent invalid byte sequence in UTF-8..., gh-15

      normalize(name) ||
      unzz(name) ||
      name
    end

    protected

    def normalize(name)

      ZONE_ALIASES[name.sub(/ Daylight /, ' Standard ')]
    end

    def unzz(name)

      m = name.match(/\A([A-Z]{3,4})([+-])(\d{1,2}):?(\d{2})?\z/)
      return nil unless m

      abbs = [ m[1] ]; a = m[1]
      abbs << "#{a}T" if a.size < 4

      off =
        (m[2] == '+' ? 1 : -1) *
        (m[3].to_i * 3600 + (m[4] || '0').to_i * 60)

      t = Time.now
      twin = Time.utc(t.year, 1, 1) # winter
      tsum = Time.utc(t.year, 7, 1) # summer

      tz_all
        .each { |tz|
          abbs.each { |abb|
            per = tz.period_for_utc(twin)
            return tz.name \
              if per.abbreviation.to_s == abb && per.utc_total_offset == off
            per = tz.period_for_utc(tsum)
            return tz.name \
              if per.abbreviation.to_s == abb && per.utc_total_offset == off } }

      nil
    end

    def determine_local_tzones

      tabbs = (-6..5)
        .collect { |i|
          t = Time.now + i * 30 * 24 * 3600
          "#{t.zone}_#{t.utc_offset}" }
        .uniq
        .sort
        .join('|')

      t = Time.now
      #tu = t.dup.utc # /!\ dup is necessary, #utc modifies its target

      twin = Time.local(t.year, 1, 1) # winter
      tsum = Time.local(t.year, 7, 1) # summer

      @tz_winter_summer ||= {}

      @tz_winter_summer[tabbs] ||= tz_all
        .select { |tz|
          pw = tz.period_for_local(twin)
          ps = tz.period_for_local(tsum)
          tabbs ==
            [ "#{pw.abbreviation}_#{pw.utc_total_offset}",
              "#{ps.abbreviation}_#{ps.utc_total_offset}" ]
              .uniq.sort.join('|') }

      @tz_winter_summer[tabbs]
    end

    def custom_tzs; @custom_tzs ||= {}; end
    def tz_all; @tz_all ||= ::TZInfo::Timezone.all; end
  end

  # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones
  # https://support.microsoft.com/en-ca/help/973627/microsoft-time-zone-index-values
  # https://ss64.com/nt/timezones.html

  ZONE_ALIASES = {
    'Coordinated Universal Time' => 'UTC',
    'Afghanistan Standard Time' => 'Asia/Kabul',
    'FLE Standard Time' => 'Europe/Helsinki',
    'Central Europe Standard Time' => 'Europe/Prague',
    'UTC-11' => 'Etc/GMT+11',
    'W. Europe Standard Time' => 'Europe/Rome',
    'W. Central Africa Standard Time' => 'Africa/Lagos',
    'SA Western Standard Time' => 'America/La_Paz',
    'Pacific SA Standard Time' => 'America/Santiago',
    'Argentina Standard Time' => 'America/Argentina/Buenos_Aires',
    'Caucasus Standard Time' => 'Asia/Yerevan',
    'AUS Eastern Standard Time' => 'Australia/Sydney',
    'Azerbaijan Standard Time' => 'Asia/Baku',
    'Eastern Standard Time' => 'America/New_York',
    'Arab Standard Time' => 'Asia/Riyadh',
    'Bangladesh Standard Time' => 'Asia/Dhaka',
    'Belarus Standard Time' => 'Europe/Minsk',
    'Romance Standard Time' => 'Europe/Paris',
    'Central America Standard Time' => 'America/Belize',
    'Atlantic Standard Time' => 'Atlantic/Bermuda',
    'Venezuela Standard Time' => 'America/Caracas',
    'Central European Standard Time' => 'Europe/Warsaw',
    'South Africa Standard Time' => 'Africa/Johannesburg',
    #'UTC' => 'Etc/UTC', # 'UTC' is good as is
    'E. South America Standard Time' => 'America/Sao_Paulo',
    'Central Asia Standard Time' => 'Asia/Almaty',
    'Singapore Standard Time' => 'Asia/Singapore',
    'Greenwich Standard Time' => 'Africa/Monrovia',
    'Cape Verde Standard Time' => 'Atlantic/Cape_Verde',
    'SE Asia Standard Time' => 'Asia/Bangkok',
    'SA Pacific Standard Time' => 'America/Bogota',
    'China Standard Time' => 'Asia/Shanghai',
    'Myanmar Standard Time' => 'Asia/Yangon',
    'E. Africa Standard Time' => 'Africa/Nairobi',
    'Hawaiian Standard Time' => 'Pacific/Honolulu',
    'E. Europe Standard Time' => 'Europe/Nicosia',
    'Tokyo Standard Time' => 'Asia/Tokyo',
    'Egypt Standard Time' => 'Africa/Cairo',
    'SA Eastern Standard Time' => 'America/Cayenne',
    'GMT Standard Time' => 'Europe/London',
    'Fiji Standard Time' => 'Pacific/Fiji',
    'West Asia Standard Time' => 'Asia/Tashkent',
    'Georgian Standard Time' => 'Asia/Tbilisi',
    'GTB Standard Time' => 'Europe/Athens',
    'Greenland Standard Time' => 'America/Godthab',
    'West Pacific Standard Time' => 'Pacific/Guam',
    'Mauritius Standard Time' => 'Indian/Mauritius',
    'India Standard Time' => 'Asia/Kolkata',
    'Iran Standard Time' => 'Asia/Tehran',
    'Arabic Standard Time' => 'Asia/Baghdad',
    'Israel Standard Time' => 'Asia/Jerusalem',
    'Jordan Standard Time' => 'Asia/Amman',
    'UTC+12' => 'Etc/GMT-12',
    'Korea Standard Time' => 'Asia/Seoul',
    'Middle East Standard Time' => 'Asia/Beirut',
    'Central Standard Time (Mexico)' => 'America/Mexico_City',
    'Ulaanbaatar Standard Time' => 'Asia/Ulaanbaatar',
    'Morocco Standard Time' => 'Africa/Casablanca',
    'Namibia Standard Time' => 'Africa/Windhoek',
    'Nepal Standard Time' => 'Asia/Kathmandu',
    'Central Pacific Standard Time' => 'Etc/GMT-11',
    'New Zealand Standard Time' => 'Pacific/Auckland',
    'Arabian Standard Time' => 'Asia/Dubai',
    'Pakistan Standard Time' => 'Asia/Karachi',
    'Paraguay Standard Time' => 'America/Asuncion',
    'Pacific Standard Time' => 'America/Los_Angeles',
    'Russian Standard Time' => 'Europe/Moscow',
    'Samoa Standard Time' => 'Pacific/Pago_Pago',
    'UTC-02' => 'Etc/GMT+2',
    'Sri Lanka Standard Time' => 'Asia/Kolkata',
    'Syria Standard Time' => 'Asia/Damascus',
    'Taipei Standard Time' => 'Asia/Taipei',
    'Tonga Standard Time' => 'Pacific/Tongatapu',
    'Turkey Standard Time' => 'Asia/Istanbul',
    'Montevideo Standard Time' => 'America/Montevideo',

    'CST5CDT' => 'CST6CDT',

    'Alaskan Standard Time' => 'America/Anchorage',
    'Central Standard Time' => 'America/Chicago',
    'Mountain Standard Time' => 'America/Denver',
    'US Eastern Standard Time' => 'America/Indiana/Indianapolis',
    'US Mountain Standard Time' => 'America/Phoenix'
  }
end

