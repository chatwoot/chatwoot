
module EtOrbi

  class << self

    def platform_info

      etos = Proc.new { |k, v| "#{k}:#{v.inspect}" }

      h = {
        'etz' => ENV['TZ'],
        'tnz' => Time.now.zone,
        'tziv' => tzinfo_version,
        'tzidv' => tzinfo_data_version,
        'rv' => RUBY_VERSION,
        'rp' => RUBY_PLATFORM,
        'win' => Gem.win_platform?,
        'rorv' => (Rails::VERSION::STRING rescue nil),
        'astz' => ([ Time.zone.class, Time.zone.tzinfo.name ] rescue nil),
        'eov' => EtOrbi::VERSION,
        'eotnz' => '???',
        'eotnfz' => '???',
        'eotlzn' => '???' }
      if ltz = EtOrbi::EoTime.local_tzone
        h['eotnz'] = EtOrbi::EoTime.now.zone
        h['eotnfz'] = EtOrbi::EoTime.now.strftime('%z')
        h['eotnfZ'] = EtOrbi::EoTime.now.strftime('%Z')
        h['eotlzn'] = ltz.name
      end

      "(#{h.map(&etos).join(',')},#{gather_tzs.map(&etos).join(',')})"
    end

    # For `make info`
    #
    def _make_info

      puts render_nozone_time(Time.now.to_f)
      puts platform_info
    end

    def render_nozone_time(seconds)

      t =
        Time.utc(1970) + seconds
      ts =
        t.strftime('%Y-%m-%d %H:%M:%S') +
        ".#{(seconds % 1).to_s.split('.').last}"
      tz =
        EtOrbi.determine_local_tzone
      z =
        tz ? tz.period_for_local(t).abbreviation.to_s : nil

      "(secs:#{seconds},utc~:#{ts.inspect},ltz~:#{z.inspect})"
    end

    protected

    def tzinfo_version

      #TZInfo::VERSION
      Gem.loaded_specs['tzinfo'].version.to_s
    rescue => err
      err.inspect
    end

    def tzinfo_data_version

      #TZInfo::Data::VERSION rescue nil
      Gem.loaded_specs['tzinfo-data'].version.to_s rescue nil
    end
  end
end

