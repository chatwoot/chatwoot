class Api::V2::Accounts::PromptsController < Api::V1::Accounts::BaseController
  before_action :find_prompt, only: [:update]
  before_action :check_prompts_feature_enabled

  def index
    @prompts = Current.account.account_prompts
    render json: @prompts
  end

  def update
    if @prompt.update(prompt_params)
      render json: @prompt
    else
      render json: @prompt.errors, status: :unprocessable_entity
    end
  end

  private

  def find_prompt
    @prompt = Current.account.account_prompts.find(params[:id])
  end

  def prompt_params
    params.require(:prompt).permit(:text, :prompt_key)
  end

  def check_prompts_feature_enabled
    return if Current.account.feature_enabled?('prompts')

    render json: { error: 'Prompts feature is not enabled for this account' }, status: :forbidden
  end
end