require 'facebook/messenger/configuration/app_secret_proof_calculator'

module Facebook
  module Messenger
    class Configuration
      module Providers
        # This is the base configuration provider.
        #   User can overwrite this class to customize the environment variables
        #   Be sure to implement all the functions as it raises
        #   NotImplementedError errors.
        class Base
          # A default caching implentation of generating the app_secret_proof
          # for a given page_id
          def app_secret_proof_for(page_id = nil)
            memo_key = [app_secret_for(page_id), access_token_for(page_id)]
            memoized_app_secret_proofs[memo_key] ||=
              calculate_app_secret_proof(*memo_key)
          end

          def valid_verify_token?(*)
            raise NotImplementedError
          end

          def app_secret_for(*)
            raise NotImplementedError
          end

          def access_token_for(*)
            raise NotImplementedError
          end

          private

          def calculate_app_secret_proof(app_secret, access_token)
            Facebook::Messenger::Configuration::AppSecretProofCalculator.call(
              app_secret,
              access_token
            )
          end

          def memoized_app_secret_proofs
            @memoized_app_secret_proofs ||= {}
          end
        end
      end
    end
  end
end
