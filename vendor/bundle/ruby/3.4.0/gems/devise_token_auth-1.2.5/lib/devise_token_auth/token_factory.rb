require 'bcrypt'

module DeviseTokenAuth
  # A token management factory which allow generate token objects and check them.
  module TokenFactory
    # For BCrypt::Password class see:
    # https://github.com/codahale/bcrypt-ruby/blob/master/lib/bcrypt/password.rb

    # Creates a token instance. Takes an optional client, lifespan and cost options.
    # Example:
    #   DeviseTokenAuth::TokenFactory.create
    #   => #<struct DeviseTokenAuth::TokenFactory::Token client="tElcgkdZ7f9XEa0unZhrYQ", token="rAMcWOs0-mGHFMnIgJD2cA", token_hash="$2a$10$wrsdlHVRGlYW11wfImxU..jr0Ux3bHo/qbXcSfgp8zmvVUNHosita", expiry=1518982690>
    #
    #   DeviseTokenAuth::TokenFactory.create(lifespan: 10, cost: 4)
    #   => #<struct DeviseTokenAuth::TokenFactory::Token client="5qleT7_t9JPVcX9xmxkVYA", token="RBXX43u4xXNSO-fr2N_4pA", token_hash="$2a$04$9gpCaoFbu2dUKxU3qiTgluHX7jj9UzS.jq1QW0EkQmoaxARo1WxTy", expiry=1517773268>
    def self.create(client: nil, lifespan: nil, cost: nil)
      # obj_client  = client.nil? ? client() : client
      obj_client  = client || client()
      obj_token      = token
      obj_token_hash = token_hash(obj_token, cost)
      obj_expiry     = expiry(lifespan)

      Token.new(obj_client, obj_token, obj_token_hash, obj_expiry)
    end

    # Generates a random URL-safe client.
    # Example:
    #   DeviseTokenAuth::TokenFactory.client
    #   => "zNf0pNP5iGfuBItZJGCseQ"
    def self.client
      secure_string
    end

    # Generates a random URL-safe token.
    # Example:
    #   DeviseTokenAuth::TokenFactory.token
    #   => "6Bqs4K9x8ChLmZogvruF3A"
    def self.token
      secure_string
    end

    # Returns token hash for a token with given cost. If no cost value is specified,
    # the default value is used. The possible cost value is within range from 4 to 31.
    # It is recommended to not use a value more than 10.
    # Example:
    #   DeviseTokenAuth::TokenFactory.token_hash("_qxAxmc-biQLiYRHsmwd5Q")
    #   => "$2a$10$6/cTAtQ3CBLfpkeHW7dlt.PD2aVCbFRN5vDDJUUhGsZ6pzYFlh4Me"
    #
    #   DeviseTokenAuth::TokenFactory.token_hash("_qxAxmc-biQLiYRHsmwd5Q", 4)
    #   => "$2a$04$RkIrosbdRtuet2eUk3si8eS4ufeNpiPc/rSSsfpniRK8ogM5YFOWS"
    def self.token_hash(token, cost = nil)
      cost ||= DeviseTokenAuth.token_cost
      BCrypt::Password.create(token, cost: cost)
    end

    # Returns the value of time as an integer number of seconds. Takes one argument.
    # Example:
    #   DeviseTokenAuth::TokenFactory.expiry
    #   => 1518983359
    #   DeviseTokenAuth::TokenFactory.expiry(10)
    #   => 1517773781
    def self.expiry(lifespan = nil)
      lifespan ||= DeviseTokenAuth.token_lifespan
      (Time.zone.now + lifespan).to_i
    end

    # Generates a random URL-safe string.
    # Example:
    #   DeviseTokenAuth::TokenFactory.secure_string
    #   => "ADBoIaqXsEDnxIpOuumrTA"
    def self.secure_string
      # https://ruby-doc.org/stdlib-2.5.0/libdoc/securerandom/rdoc/Random/Formatter.html#method-i-urlsafe_base64
      SecureRandom.urlsafe_base64
    end

    # Returns true if token hash is a valid token hash.
    # Example:
    #   token_hash = "$2a$10$ArjX0tskRIa5Z/Tmapy59OCiAXLStfhrCiaDz.8fCb6hnX1gJ0p/2"
    #   DeviseTokenAuth::TokenFactory.valid_token_hash?(token_hash)
    #   => true
    def self.valid_token_hash?(token_hash)
      !!BCrypt::Password.valid_hash?(token_hash)
    end

    # Compares a potential token against the token hash. Returns true if the token is the original token, false otherwise.
    # Example:
    #   token = "4wZ9gcc900rMQD1McpcSNA"
    #   token_hash = "$2a$10$ArjX0tskRIa5Z/Tmapy59OCiAXLStfhrCiaDz.8fCb6hnX1gJ0p/2"
    #   DeviseTokenAuth::TokenFactory.token_hash_is_token?(token_hash, token)
    #   => true
    def self.token_hash_is_token?(token_hash, token)
      BCrypt::Password.new(token_hash).is_password?(token)
    rescue StandardError
      false
    end

    # Creates a token instance with instance variables equal nil.
    # Example:
    #   DeviseTokenAuth::TokenFactory.new
    #   => #<struct DeviseTokenAuth::TokenFactory::Token client=nil, token=nil, token_hash=nil, expiry=nil>
    def self.new
      Token.new
    end

    Token = Struct.new(:client, :token, :token_hash, :expiry) do
      # Sets all instance variables of the token to nil. It is faster than creating new empty token.
      # Example:
      #   token.clear!
      #   => true
      #   token
      #   => #<struct DeviseTokenAuth::TokenFactory::Token client=nil, token=nil, token_hash=nil, expiry=nil>
      def clear!
        size.times { |i| self[i] = nil }
        true
      end

      # Checks token attribute presence
      # Example:
      #   token.present?
      #   => true
      def present?
        token.present?
      end
    end
  end
end
