module Enterprise::Api::V1::Accounts::CsatSurveyResponsesController
  def update
    @csat_survey_response = Current.account.csat_survey_responses.find(params[:id])
    authorize @csat_survey_response

    @csat_survey_response.update!(
      csat_review_notes: params[:csat_review_notes],
      review_notes_updated_by: Current.user,
      review_notes_updated_at: Time.current
    )
  end
end
