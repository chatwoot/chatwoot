module Facebook
  module Messenger
    class Configuration
      # We provide a service to calculate an app_secret_proof
      class AppSecretProofCalculator
        def self.call(app_secret, access_token)
          OpenSSL::HMAC.hexdigest(
            OpenSSL::Digest.new('SHA256'.freeze),
            app_secret,
            access_token
          )
        end
      end
    end
  end
end
