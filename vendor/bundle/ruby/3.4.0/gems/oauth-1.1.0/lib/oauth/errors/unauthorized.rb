# frozen_string_literal: true

module OAuth
  class Unauthorized < OAuth::Error
    attr_reader :request

    def initialize(request = nil)
      super()
      @request = request
    end

    def to_s
      return "401 Unauthorized" if request.nil?

      "#{request.code} #{request.message}"
    end
  end
end
