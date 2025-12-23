# frozen_string_literal: true

module Sidekiq
  # Sidekiq::Job is a new alias for Sidekiq::Worker as of Sidekiq 6.3.0.
  # Use `include Sidekiq::Job` rather than `include Sidekiq::Worker`.
  #
  # The term "worker" is too generic and overly confusing, used in several
  # different contexts meaning different things. Many people call a Sidekiq
  # process a "worker". Some people call the thread that executes jobs a
  # "worker". This change brings Sidekiq closer to ActiveJob where your job
  # classes extend ApplicationJob.
  Worker = Job
end
