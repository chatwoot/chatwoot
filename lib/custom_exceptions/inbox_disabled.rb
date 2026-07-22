# frozen_string_literal: true

class CustomExceptions::InboxDisabled < CustomExceptions::Base
  def initialize(data = {})
    super
  end

  def message
    'This inbox is currently disabled'
  end

  def error_code
    'inbox_disabled'
  end

  def http_status
    :forbidden
  end
end
