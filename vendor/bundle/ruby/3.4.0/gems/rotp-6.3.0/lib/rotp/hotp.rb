module ROTP
  class HOTP < OTP
    # Generates the OTP for the given count
    # @param [Integer] count counter
    # @returns [Integer] OTP
    def at(count)
      generate_otp(count)
    end

    # Verifies the OTP passed in against the current time OTP
    # @param otp [String/Integer] the OTP to check against
    # @param counter [Integer] the counter of the OTP
    # @param retries [Integer] number of counters to incrementally retry
    def verify(otp, counter, retries: 0)
      counters = (counter..counter + retries).to_a
      counters.find do |c|
        super(otp, at(c))
      end
    end

    # Returns the provisioning URI for the OTP
    # This can then be encoded in a QR Code and used
    # to provision the Google Authenticator app
    # @param [String] name of the account
    # @param [Integer] initial_count starting counter value, defaults to 0
    # @return [String] provisioning uri
    def provisioning_uri(name = nil, initial_count = 0)
      OTP::URI.new(self, account_name: name || @name, counter: initial_count).to_s
    end
  end
end
