module ROTP
  DEFAULT_INTERVAL = 30
  class TOTP < OTP
    attr_reader :interval, :issuer

    # @option options [Integer] interval (30) the time interval in seconds for OTP
    #     This defaults to 30 which is standard.
    def initialize(s, options = {})
      @interval = options[:interval] || DEFAULT_INTERVAL
      @issuer = options[:issuer]
      super
    end

    # Accepts either a Unix timestamp integer or a Time object.
    # Time objects will be adjusted to UTC automatically
    # @param time [Time/Integer] the time to generate an OTP for, integer unix timestamp or Time object
    def at(time)
      generate_otp(timecode(time))
    end

    # Generate the current time OTP
    # @return [Integer] the OTP as an integer
    def now
      generate_otp(timecode(Time.now))
    end

    # Verifies the OTP passed in against the current time OTP
    # and adjacent intervals up to +drift+.  Excludes OTPs
    # from `after` and earlier.  Returns time value of
    # matching OTP code for use in subsequent call.
    # @param otp [String] the one time password to verify
    # @param drift_behind [Integer] how many seconds to look back
    # @param drift_ahead [Integer] how many seconds to look ahead
    # @param after [Integer] prevent token reuse, last login timestamp
    # @param at [Time] time at which to generate and verify a particular
    #   otp. default Time.now
    # @return [Integer, nil] the last successful timestamp
    #   interval
    def verify(otp, drift_ahead: 0, drift_behind: 0, after: nil, at: Time.now)
      timecodes = get_timecodes(at, drift_behind, drift_ahead)

      timecodes = timecodes.select { |t| t > timecode(after) } if after

      result = nil
      timecodes.each do |t|
        result = t * interval if super(otp, generate_otp(t))
      end
      result
    end

    # Returns the provisioning URI for the OTP
    # This can then be encoded in a QR Code and used
    # to provision the Google Authenticator app
    # @param [String] name of the account
    # @return [String] provisioning URI
    def provisioning_uri(name = nil)
      OTP::URI.new(self, account_name: name || @name).to_s
    end

    private

    # Get back an array of timecodes for a period
    def get_timecodes(at, drift_behind, drift_ahead)
      now = timeint(at)
      timecode_start = timecode(now - drift_behind)
      timecode_end = timecode(now + drift_ahead)
      (timecode_start..timecode_end).step(1).to_a
    end

    # Ensure UTC int
    def timeint(time)
      return time.to_i unless time.class == Time

      time.utc.to_i
    end

    def timecode(time)
      timeint(time) / interval
    end
  end
end
