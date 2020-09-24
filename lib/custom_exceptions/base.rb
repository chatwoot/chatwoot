# frozen_string_literal: true

class CustomExceptions::Base < ::StandardError
  def to_hash
    {
      message: message
    }
  end

  def http_status
    403
  end

  def initialize(data)
    @data = data
    super()
  end
end
