class Api::V1::Accounts::SurveysController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :check_authorization
  before_action :set_survey, except: [:index, :create]

  def index
    @surveys = Current.account.surveys.includes(survey_questions: :survey_question_options).order(created_at: :desc)
  end

  def show; end

  def create
    @survey = Current.account.surveys.create!(survey_params)
  end

  def update
    @survey.update!(survey_params)
    @survey.reload
  end

  def destroy
    @survey.destroy!
    head :ok
  end

  private

  def set_survey
    @survey = Current.account.surveys.includes(survey_questions: :survey_question_options).find(params[:id])
  end

  def survey_params
    params.permit(
      :name,
      :description,
      :active,
      survey_questions_attributes: [
        :id,
        :question_text,
        :question_type,
        :input_type,
        :position,
        :required,
        :_destroy,
        { survey_question_options_attributes: [:id, :option_text, :position, :_destroy] }
      ]
    )
  end
end
