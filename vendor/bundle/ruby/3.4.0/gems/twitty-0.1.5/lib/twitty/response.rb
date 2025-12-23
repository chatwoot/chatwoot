# frozen_string_literal: true

class Twitty::Response
  attr_reader :raw_response

  def initialize(raw_response)
    @raw_response = raw_response
  end

  def body
    JSON.parse(raw_response.body)
  end

  def status
    raw_response.code
  end
end
