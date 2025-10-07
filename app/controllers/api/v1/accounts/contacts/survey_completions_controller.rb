class Api::V1::Accounts::Contacts::SurveyCompletionsController < Api::V1::Accounts::Contacts::BaseController
  def index
    if params[:survey_id].present?
      # Get completion status for a specific survey
      survey = Current.account.surveys.find(params[:survey_id])
      render json: survey_completion_status(survey)
    else
      # Get all completed surveys for this contact
      @completions = @contact.contact_survey_completions.includes(:survey)
      render json: @completions.map { |c| completion_summary(c) }
    end
  end

  private

  def survey_completion_status(survey)
    required_questions = survey.survey_questions.where(required: true)
    all_questions = survey.survey_questions
    answered_questions = @contact.survey_answers.where(survey_question_id: all_questions.pluck(:id))
    answered_required = @contact.survey_answers.where(survey_question_id: required_questions.pluck(:id))
    completion = @contact.contact_survey_completions.find_by(survey: survey)

    {
      survey_id: survey.id,
      survey_name: survey.name,
      is_completed: completion.present?,
      completed_at: completion&.completed_at,
      total_questions: all_questions.count,
      answered_questions: answered_questions.count,
      required_questions: required_questions.count,
      required_answered: answered_required.count,
      progress_percentage: calculate_progress(all_questions.count, answered_questions.count)
    }
  end

  def completion_summary(completion)
    {
      survey_id: completion.survey.id,
      survey_name: completion.survey.name,
      completed_at: completion.completed_at
    }
  end

  def calculate_progress(total, answered)
    return 0 if total.zero?

    ((answered.to_f / total) * 100).round(2)
  end
end
