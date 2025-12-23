# frozen_string_literal: true

module OAuth
  # Superclass for tokens used by OAuth Clients
  class ConsumerToken < Token
    attr_accessor :consumer, :params
    attr_reader   :response

    def self.from_hash(consumer, hash)
      token = new(consumer, hash[:oauth_token], hash[:oauth_token_secret])
      token.params = hash
      token
    end

    def initialize(consumer, token = "", secret = "")
      super(token, secret)
      @consumer = consumer
      @params   = {}
    end

    # Make a signed request using given http_method to the path
    #
    #   @token.request(:get,  '/people')
    #   @token.request(:post, '/people', @person.to_xml, { 'Content-Type' => 'application/xml' })
    #
    def request(http_method, path, *arguments)
      @response = consumer.request(http_method, path, self, {}, *arguments)
    end

    # Sign a request generated elsewhere using Net:HTTP::Post.new or friends
    def sign!(request, options = {})
      consumer.sign!(request, self, options)
    end
  end
end
