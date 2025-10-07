class Api::V1::Accounts::SurveyAnswersController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :set_contact
  before_action :set_survey_question

  def create
    @survey_answer = Current.account.survey_answers.find_or_initialize_by(
      contact: @contact,
      survey_question: @survey_question
    )

    @survey_answer.assign_attributes(survey_answer_params)

    if @survey_answer.save
      check_and_mark_survey_completion
      render json: @survey_answer, status: :created
    else
      render json: { errors: @survey_answer.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_contact
    @contact = Current.account.contacts.find(params[:contact_id])
  end

  def set_survey_question
    @survey_question = SurveyQuestion.joins(:survey)
                                     .where(surveys: { account_id: Current.account.id })
                                     .find(params[:survey_question_id])
  end

  def survey_answer_params
    params.permit(:answer_text, :survey_question_option_id)
  end

  def check_and_mark_survey_completion
    survey = @survey_question.survey

    # Get all required questions for this survey
    required_question_ids = survey.survey_questions.where(required: true).pluck(:id)

    # Get all answered required questions by this contact
    answered_question_ids = @contact.survey_answers
                                    .where(survey_question_id: required_question_ids)
                                    .pluck(:survey_question_id)

    # Check if all required questions have been answered
    return unless required_question_ids.sort == answered_question_ids.sort

    # Mark survey as completed (idempotent - won't duplicate if already exists)
    @contact.contact_survey_completions.find_or_create_by!(
      survey: survey,
      account: Current.account
    ) do |completion|
      completion.completed_at = Time.current
    end
  end
end
