# frozen_string_literal: true

module OAuth
  # Used on the server for generating tokens
  class ServerToken < Token
    def initialize
      super(generate_key(16), generate_key)
    end
  end
end
