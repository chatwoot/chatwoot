json.array! @csat_survey_responses do |csat_survey_response|
  json.partial! 'api/v1/models/csat_survey_response', formats: [:json], resource: csat_survey_response
end
