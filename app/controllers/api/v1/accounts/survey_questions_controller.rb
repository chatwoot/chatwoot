class Api::V1::Accounts::SurveyQuestionsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :set_survey
  before_action :check_authorization
  before_action :set_question, except: [:index, :create]

  def index
    @questions = @survey.survey_questions.includes(:survey_question_options)
  end

  def show; end

  def create
    @question = @survey.survey_questions.create!(question_params)
  end

  def update
    @question.update!(question_params)
  end

  def destroy
    @question.destroy!
    head :ok
  end

  private

  def set_survey
    @survey = Current.account.surveys.find(params[:survey_id])
  end

  def set_question
    @question = @survey.survey_questions.find(params[:id])
  end

  def question_params
    params.permit(
      :question_text,
      :question_type,
      :input_type,
      :position,
      :required,
      survey_question_options_attributes: [:id, :option_text, :position, :_destroy]
    )
  end

  def check_authorization
    authorize(SurveyQuestion)
  end
end
