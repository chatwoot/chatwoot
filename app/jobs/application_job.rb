class ApplicationJob < ActiveJob::Base
  # https://api.rubyonrails.org/v5.2.1/classes/ActiveJob/Exceptions/ClassMethods.html
  discard_on ActiveJob::DeserializationError do |job, error|
    # rubocop:disable Layout/LineLength
    Rails.logger.info("Skipping #{job.class} with #{job.instance_variable_get(:@serialized_arguments)} because of ActiveJob::DeserializationError (#{error.message})")
    # rubocop:enable Layout/LineLength
  end
end
