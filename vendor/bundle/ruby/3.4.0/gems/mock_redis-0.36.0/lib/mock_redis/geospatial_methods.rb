class MockRedis
  module GeospatialMethods
    LNG_RANGE = (-180..180).freeze
    LAT_RANGE = (-85.05112878..85.05112878).freeze
    STEP = 26
    UNITS = {
      m: 1,
      km: 1000,
      ft: 0.3048,
      mi: 1609.34
    }.freeze
    D_R = Math::PI / 180.0
    EARTH_RADIUS_IN_METERS = 6_372_797.560856

    ruby2_keywords def geoadd(key, *args)
      points = parse_points(args)

      scored_points = points.map do |point|
        score = geohash_encode(point[:lng], point[:lat])[:bits]
        [score.to_s, point[:key]]
      end

      zadd(key, scored_points)
    end

    def geodist(key, member1, member2, unit = 'm')
      to_meter = parse_unit(unit)

      return nil if zcard(key).zero?

      score1 = zscore(key, member1)
      score2 = zscore(key, member2)
      return nil if score1.nil? || score2.nil?
      hash1 = { bits: score1.to_i, step: STEP }
      hash2 = { bits: score2.to_i, step: STEP }

      lng1, lat1 = geohash_decode(hash1)
      lng2, lat2 = geohash_decode(hash2)

      distance = geohash_distance(lng1, lat1, lng2, lat2) / to_meter
      format('%<distance>.4f', distance: distance)
    end

    def geohash(key, members)
      lng_range = (-180..180)
      lat_range = (-90..90)
      geoalphabet = '0123456789bcdefghjkmnpqrstuvwxyz'

      Array(members).map do |member|
        score = zscore(key, member)
        next nil unless score
        score = score.to_i
        hash = { bits: score, step: STEP }
        lng, lat = geohash_decode(hash)
        bits = geohash_encode(lng, lat, lng_range, lat_range)[:bits]
        hash = ''
        11.times do |i|
          shift = (52 - ((i + 1) * 5))
          idx = shift > 0 ? (bits >> shift) & 0x1f : 0
          hash << geoalphabet[idx]
        end
        hash
      end
    end

    def geopos(key, members)
      Array(members).map do |member|
        score = zscore(key, member)
        next nil unless score
        hash = { bits: score.to_i, step: STEP }
        lng, lat = geohash_decode(hash)
        lng = format_decoded_coord(lng)
        lat = format_decoded_coord(lat)
        [lng, lat]
      end
    end

    private

    def parse_points(args)
      points = args.each_slice(3).to_a

      if points.last.size != 3
        raise Redis::CommandError,
          "ERR wrong number of arguments for 'geoadd' command"
      end

      points.map do |point|
        parse_point(point)
      end
    end

    def parse_point(point)
      lng = Float(point[0])
      lat = Float(point[1])

      unless LNG_RANGE.include?(lng) && LAT_RANGE.include?(lat)
        lng = format('%<long>.6f', long: lng)
        lat = format('%<lat>.6f', lat: lat)
        raise Redis::CommandError,
          "ERR invalid longitude,latitude pair #{lng},#{lat}"
      end

      { key: point[2], lng: lng, lat: lat }
    rescue ArgumentError
      raise Redis::CommandError, 'ERR value is not a valid float'
    end

    # Returns ZSET score for passed coordinates
    def geohash_encode(lng, lat, lng_range = LNG_RANGE, lat_range = LAT_RANGE, step = STEP)
      lat_offset = (lat - lat_range.min) / (lat_range.max - lat_range.min)
      lng_offset = (lng - lng_range.min) / (lng_range.max - lng_range.min)

      lat_offset *= (1 << step)
      lng_offset *= (1 << step)

      bits = interleave(lat_offset.to_i, lng_offset.to_i)

      { bits: bits, step: step }
    end

    def interleave(x, y)
      b = [0x5555555555555555, 0x3333333333333333, 0x0F0F0F0F0F0F0F0F,
           0x00FF00FF00FF00FF, 0x0000FFFF0000FFFF]
      s = [1, 2, 4, 8, 16]

      x = (x | (x << s[4])) & b[4]
      y = (y | (y << s[4])) & b[4]

      x = (x | (x << s[3])) & b[3]
      y = (y | (y << s[3])) & b[3]

      x = (x | (x << s[2])) & b[2]
      y = (y | (y << s[2])) & b[2]

      x = (x | (x << s[1])) & b[1]
      y = (y | (y << s[1])) & b[1]

      x = (x | (x << s[0])) & b[0]
      y = (y | (y << s[0])) & b[0]

      x | (y << 1)
    end

    # Decodes ZSET score to coordinates pair
    def geohash_decode(hash, lng_range = LNG_RANGE, lat_range = LAT_RANGE)
      area = calculate_approximate_area(hash, lng_range, lat_range)

      lng = (area[:lng_min] + area[:lng_max]) / 2
      lat = (area[:lat_min] + area[:lat_max]) / 2

      [lng, lat]
    end

    def calculate_approximate_area(hash, lng_range, lat_range)
      bits = hash[:bits]
      step = hash[:step]
      hash_sep = deinterleave(bits)

      lat_scale = lat_range.max - lat_range.min
      lng_scale = lng_range.max - lng_range.min

      ilato = hash_sep & 0xFFFFFFFF # cast int64 to int32 to get lat part of deinterleaved hash
      ilngo = hash_sep >> 32        # shift over to get lng part of hash

      {
        lat_min: lat_range.min + (ilato * 1.0 / (1 << step)) * lat_scale,
        lat_max: lat_range.min + ((ilato + 1) * 1.0 / (1 << step)) * lat_scale,
        lng_min: lng_range.min + (ilngo * 1.0 / (1 << step)) * lng_scale,
        lng_max: lng_range.min + ((ilngo + 1) * 1.0 / (1 << step)) * lng_scale
      }
    end

    def deinterleave(bits)
      b = [0x5555555555555555, 0x3333333333333333, 0x0F0F0F0F0F0F0F0F,
           0x00FF00FF00FF00FF, 0x0000FFFF0000FFFF, 0x00000000FFFFFFFF]
      s = [0, 1, 2, 4, 8, 16]

      x = bits
      y = bits >> 1

      x = (x | (x >> s[0])) & b[0]
      y = (y | (y >> s[0])) & b[0]

      x = (x | (x >> s[1])) & b[1]
      y = (y | (y >> s[1])) & b[1]

      x = (x | (x >> s[2])) & b[2]
      y = (y | (y >> s[2])) & b[2]

      x = (x | (x >> s[3])) & b[3]
      y = (y | (y >> s[3])) & b[3]

      x = (x | (x >> s[4])) & b[4]
      y = (y | (y >> s[4])) & b[4]

      x = (x | (x >> s[5])) & b[5]
      y = (y | (y >> s[5])) & b[5]

      x | (y << 32)
    end

    def format_decoded_coord(coord)
      coord = format('%<coord>.17f', coord: coord)
      l = 1
      l += 1 while coord[-l] == '0'
      coord = coord[0..-l]
      coord[-1] == '.' ? coord[0..-2] : coord
    end

    def parse_unit(unit)
      unit = unit.to_sym
      return UNITS[unit] if UNITS[unit]

      raise Redis::CommandError,
        'ERR unsupported unit provided. please use m, km, ft, mi'
    end

    def geohash_distance(lng1d, lat1d, lng2d, lat2d)
      lat1r = deg_rad(lat1d)
      lng1r = deg_rad(lng1d)
      lat2r = deg_rad(lat2d)
      lng2r = deg_rad(lng2d)

      u = Math.sin((lat2r - lat1r) / 2)
      v = Math.sin((lng2r - lng1r) / 2)

      2.0 * EARTH_RADIUS_IN_METERS *
        Math.asin(Math.sqrt(u * u + Math.cos(lat1r) * Math.cos(lat2r) * v * v))
    end

    def deg_rad(ang)
      ang * D_R
    end

    def rad_deg(ang)
      ang / D_R
    end
  end
end
