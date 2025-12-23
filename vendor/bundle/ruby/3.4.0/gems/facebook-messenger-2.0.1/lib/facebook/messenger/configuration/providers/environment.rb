require 'facebook/messenger/configuration/providers/base'

module Facebook
  module Messenger
    class Configuration
      module Providers
        # The default configuration provider for environment variables.
        class Environment < Base
          def valid_verify_token?(verify_token)
            verify_token == ENV['VERIFY_TOKEN']
          end

          # Return String of app secret of Facebook App.
          # Make sure you are returning the app secret if you overwrite
          # configuration provider class as this app secret is used to
          # validate the incoming requests.
          def app_secret_for(*)
            ENV['APP_SECRET']
          end

          # Return String of page access token.
          def access_token_for(*)
            ENV['ACCESS_TOKEN']
          end
        end
      end
    end
  end
end
