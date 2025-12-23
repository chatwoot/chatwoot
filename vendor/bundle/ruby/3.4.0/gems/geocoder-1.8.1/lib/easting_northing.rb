module Geocoder
  class EastingNorthing
    attr_reader :easting, :northing, :lat_lng

    def initialize(opts)
      @easting = opts[:easting]
      @northing = opts[:northing]

      @lat_lng = to_WGS84(to_osgb_36)
    end

    private

    def to_osgb_36
      osgb_fo  = 0.9996012717
      northing0 = -100_000.0
      easting0 = 400_000.0
      phi0 = deg_to_rad(49.0)
      lambda0 = deg_to_rad(-2.0)
      a = 6_377_563.396
      b = 6_356_256.909
      eSquared = ((a * a) - (b * b)) / (a * a)
      phi = 0.0
      lambda = 0.0
      n = (a - b) / (a + b)
      m = 0.0
      phiPrime = ((northing - northing0) / (a * osgb_fo)) + phi0

      while (northing - northing0 - m) >= 0.001
        m =
          (b * osgb_fo)\
            * (((1 + n + ((5.0 / 4.0) * n * n) + ((5.0 / 4.0) * n * n * n))\
              * (phiPrime - phi0))\
              - (((3 * n) + (3 * n * n) + ((21.0 / 8.0) * n * n * n))\
                * Math.sin(phiPrime - phi0)\
                * Math.cos(phiPrime + phi0))\
              + ((((15.0 / 8.0) * n * n) + ((15.0 / 8.0) * n * n * n))\
                * Math.sin(2.0 * (phiPrime - phi0))\
                * Math.cos(2.0 * (phiPrime + phi0)))\
              - (((35.0 / 24.0) * n * n * n)\
                * Math.sin(3.0 * (phiPrime - phi0))\
                * Math.cos(3.0 * (phiPrime + phi0))))

        phiPrime += (northing - northing0 - m) / (a * osgb_fo)
      end

      v = a * osgb_fo * ((1.0 - eSquared * sin_pow_2(phiPrime))**-0.5)
      rho =
        a\
          * osgb_fo\
          * (1.0 - eSquared)\
          * ((1.0 - eSquared * sin_pow_2(phiPrime))**-1.5)
      etaSquared = (v / rho) - 1.0
      vii = Math.tan(phiPrime) / (2 * rho * v)
      viii =
        (Math.tan(phiPrime) / (24.0 * rho * (v**3.0)))\
          * (5.0\
            + (3.0 * tan_pow_2(phiPrime))\
            + etaSquared\
            - (9.0 * tan_pow_2(phiPrime) * etaSquared))
      ix =
        (Math.tan(phiPrime) / (720.0 * rho * (v**5.0)))\
          * (61.0\
            + (90.0 * tan_pow_2(phiPrime))\
            + (45.0 * tan_pow_2(phiPrime) * tan_pow_2(phiPrime)))
      x = sec(phiPrime) / v
      xi =
        (sec(phiPrime) / (6.0 * v * v * v))\
          * ((v / rho) + (2 * tan_pow_2(phiPrime)))
      xiii =
        (sec(phiPrime) / (120.0 * (v**5.0)))\
          * (5.0\
            + (28.0 * tan_pow_2(phiPrime))\
            + (24.0 * tan_pow_2(phiPrime) * tan_pow_2(phiPrime)))
      xiia =
        (sec(phiPrime) / (5040.0 * (v**7.0)))\
          * (61.0\
            + (662.0 * tan_pow_2(phiPrime))\
            + (1320.0 * tan_pow_2(phiPrime) * tan_pow_2(phiPrime))\
            + (720.0\
              * tan_pow_2(phiPrime)\
              * tan_pow_2(phiPrime)\
              * tan_pow_2(phiPrime)))
      phi =
        phiPrime\
          - (vii * ((easting - easting0)**2.0))\
          + (viii * ((easting - easting0)**4.0))\
          - (ix * ((easting - easting0)**6.0))
      lambda =
        lambda0\
          + (x * (easting - easting0))\
          - (xi * ((easting - easting0)**3.0))\
          + (xiii * ((easting - easting0)**5.0))\
          - (xiia * ((easting - easting0)**7.0))

      [rad_to_deg(phi), rad_to_deg(lambda)]
    end

    def to_WGS84(latlng)
      latitude = latlng[0]
      longitude = latlng[1]

      a = 6_377_563.396
      b = 6_356_256.909
      eSquared = ((a * a) - (b * b)) / (a * a)

      phi = deg_to_rad(latitude)
      lambda = deg_to_rad(longitude)
      v = a / Math.sqrt(1 - eSquared * sin_pow_2(phi))
      h = 0
      x = (v + h) * Math.cos(phi) * Math.cos(lambda)
      y = (v + h) * Math.cos(phi) * Math.sin(lambda)
      z = ((1 - eSquared) * v + h) * Math.sin(phi)

      tx = 446.448
      ty = -124.157
      tz = 542.060

      s  = -0.0000204894
      rx = deg_to_rad(0.00004172222)
      ry = deg_to_rad(0.00006861111)
      rz = deg_to_rad(0.00023391666)

      xB = tx + (x * (1 + s)) + (-rx * y) + (ry * z)
      yB = ty + (rz * x) + (y * (1 + s)) + (-rx * z)
      zB = tz + (-ry * x) + (rx * y) + (z * (1 + s))

      a = 6_378_137.000
      b = 6_356_752.3141
      eSquared = ((a * a) - (b * b)) / (a * a)

      lambdaB = rad_to_deg(Math.atan(yB / xB))
      p = Math.sqrt((xB * xB) + (yB * yB))
      phiN = Math.atan(zB / (p * (1 - eSquared)))

      (1..10).each do |_i|
        v = a / Math.sqrt(1 - eSquared * sin_pow_2(phiN))
        phiN1 = Math.atan((zB + (eSquared * v * Math.sin(phiN))) / p)
        phiN = phiN1
      end

      phiB = rad_to_deg(phiN)

      [phiB, lambdaB]
    end

    def deg_to_rad(degrees)
      degrees / 180.0 * Math::PI
    end

    def rad_to_deg(r)
      (r / Math::PI) * 180
    end

    def sin_pow_2(x)
      Math.sin(x) * Math.sin(x)
    end

    def cos_pow_2(x)
      Math.cos(x) * Math.cos(x)
    end

    def tan_pow_2(x)
      Math.tan(x) * Math.tan(x)
    end

    def sec(x)
      1.0 / Math.cos(x)
    end
  end
end
