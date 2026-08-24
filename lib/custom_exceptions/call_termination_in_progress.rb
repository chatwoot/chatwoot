# frozen_string_literal: true

class CustomExceptions::CallTerminationInProgress < CustomExceptions::Base
  def message
    'Call termination is already in progress'
  end

  def http_status
    409
  end
end
