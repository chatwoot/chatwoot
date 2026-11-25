# Every HTTParty call to Twilio's Content API, which is all five of the CSAT template
# ones, with the number and the reason it is that number.
#
# `max_retries: 0`: `Net::HTTP` repeats an idempotent request once by default, so the two
# reads below would otherwise cost twice what this says.
#
# One ceiling and not two, because these five are the same kind of call: they create,
# delete and read a template definition, and Twilio answers each out of its own state.
# None of them hands Twilio a body to go fetch, which is what would justify a longer wait.
#
# The number matters most on the read: `CsatSurveyService` asks whether the template is
# approved before sending a survey, and that runs once per conversation resolved, inside
# a job. A Twilio that accepts the connection and stops answering held a worker for a
# minute there, per conversation.
module Twilio::RequestOptions
  TWILIO_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze
end
