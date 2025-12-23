# frozen_string_literal: true

module WebMock
  class Config
    include Singleton

    def initialize
      @show_stubbing_instructions = true
      @show_body_diff = true
    end

    attr_accessor :allow_net_connect
    attr_accessor :allow_localhost
    attr_accessor :allow
    attr_accessor :net_http_connect_on_start
    attr_accessor :show_stubbing_instructions
    attr_accessor :query_values_notation
    attr_accessor :show_body_diff
  end
end
