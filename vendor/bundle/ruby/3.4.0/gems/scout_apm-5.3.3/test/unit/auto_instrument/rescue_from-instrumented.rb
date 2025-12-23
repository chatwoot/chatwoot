
class BrokenController < ApplicationController
  rescue_from Exception do |e|
    if e.is_a? Pundit::NotAuthorizedError
      unauthorized_error
    elsif e.is_a? ActionController::ParameterMissing
      error(status: 422, message: e.message)
    else
      log_error(e)
      error message: 'Internal error', exception: e
    end
  end
end
