module ROTP
  class OTP
    # https://github.com/google/google-authenticator/wiki/Key-Uri-Format
    class URI
      def initialize(otp, account_name: nil, counter: nil)
        @otp = otp
        @account_name = account_name || ''
        @counter = counter
      end

      def to_s
        "otpauth://#{type}/#{label}?#{parameters}"
      end

      private

      def algorithm
        return unless %w[sha256 sha512].include?(@otp.digest)

        @otp.digest.upcase
      end

      def counter
        return if @otp.is_a?(TOTP)
        fail if @counter.nil?

        @counter
      end

      def digits
        return if @otp.digits == DEFAULT_DIGITS

        @otp.digits
      end

      def issuer
        @otp.issuer&.strip&.tr(':', '_')
      end

      def label
        [issuer, @account_name.rstrip]
          .compact
          .map { |s| s.tr(':', '_') }
          .map { |s| ERB::Util.url_encode(s) }
          .join(':')
      end

      def parameters
        {
          secret: @otp.secret,
          issuer: issuer,
          algorithm: algorithm,
          digits: digits,
          period: period,
          counter: counter,
        }
          .merge(@otp.provisioning_params)
          .reject { |_, v| v.nil? }
          .map { |k, v| "#{k}=#{ERB::Util.url_encode(v)}" }
          .join('&')
      end

      def period
        return if @otp.is_a?(HOTP)
        return if @otp.interval == DEFAULT_INTERVAL

        @otp.interval
      end

      def type
        case @otp
        when TOTP then 'totp'
        when HOTP then 'hotp'
        end
      end
    end
  end
end
