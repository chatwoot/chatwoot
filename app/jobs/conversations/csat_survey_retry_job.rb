class Conversations::CsatSurveyRetryJob < ApplicationJob
  # `default` and not `low`: this runs in every deployment of the fork, and a deployment is free
  # to start its workers with an explicit `-q` list. One production deployment consumes only critical,
  # high, medium, default and scheduled_jobs, so a job queued on `low` would sit in Redis
  # untouched and the retry would silently never happen.
  queue_as :default

  def perform(conversation)
    CsatSurveyService.new(conversation: conversation).perform
  end
end
