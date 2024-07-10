class Digitaltolk::StoreSurveyResponsesParquetJob < ApplicationJob
  queue_as :default

  def perform(survey_response_ids, file_name)
    @survey_responses = CsatSurveyResponse.where(id: survey_response_ids)

    if @survey_responses.present?
      Digitaltolk::SurveyResponsesParquetService.new(@survey_responses, file_name).perform
    end
  end
end