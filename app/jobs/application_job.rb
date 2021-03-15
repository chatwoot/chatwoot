class ApplicationJob < ActiveJob::Base
  # https://api.rubyonrails.org/v5.2.1/classes/ActiveJob/Exceptions/ClassMethods.html
  discard_on ActiveJob::DeserializationError do |_job, error|
    Rails.logger.error("Skipping job because of ActiveJob::DeserializationError (#{error.message})")
  end
end
