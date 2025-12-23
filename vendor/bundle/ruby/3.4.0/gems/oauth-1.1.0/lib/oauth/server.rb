# frozen_string_literal: true

require "oauth/helper"
require "oauth/consumer"

module OAuth
  # This is mainly used to create consumer credentials and can pretty much be ignored if you want to create your own
  class Server
    include OAuth::Helper
    attr_accessor :base_url

    @@server_paths = {
      request_token_path: "/oauth/request_token",
      authorize_path: "/oauth/authorize",
      access_token_path: "/oauth/access_token"
    }

    # Create a new server instance
    def initialize(base_url, paths = {})
      @base_url = base_url
      @paths = @@server_paths.merge(paths)
    end

    def generate_credentials
      [generate_key(16), generate_key]
    end

    def generate_consumer_credentials(_params = {})
      Consumer.new(*generate_credentials)
    end

    # mainly for testing purposes
    def create_consumer
      creds = generate_credentials
      Consumer.new(creds[0], creds[1],
                   {
                     site: base_url,
                     request_token_path: request_token_path,
                     authorize_path: authorize_path,
                     access_token_path: access_token_path
                   })
    end

    def request_token_path
      @paths[:request_token_path]
    end

    def request_token_url
      base_url + request_token_path
    end

    def authorize_path
      @paths[:authorize_path]
    end

    def authorize_url
      base_url + authorize_path
    end

    def access_token_path
      @paths[:access_token_path]
    end

    def access_token_url
      base_url + access_token_path
    end
  end
end
