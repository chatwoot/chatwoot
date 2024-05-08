class Api::V1::Accounts::StagesController < Api::V1::Accounts::BaseController
  before_action :fetch_stages
  before_action :fetch_stage, only: [:show, :update, :destroy]

  def index
    render json: @stages.to_json
  end

  def show
    render json: @stage.to_json
  end

  def update
    @stage.update!(permitted_payload)
  end

  def destroy
    @stage.update!(disable: true) if @stage.allow_disabled == true
    head :no_content
  end

  private

  def fetch_stages
    @stages = Current.account.stages
    return if permitted_params[:stage_type].blank?

    stage_type = Stage::STAGE_TYPE_MAPPING[permitted_params[:stage_type]]
    both_type = Stage::STAGE_TYPE_MAPPING['both']
    @stages = @stage.where("stage_type = #{stage_type} or stage_type = #{both_type} or #{stage_type} = #{both_type}")
  end

  def fetch_stage
    @stage = Current.account.stages.find(permitted_params[:id])
  end

  def permitted_payload
    params.require(:stage).permit(
      :name,
      :description
    )
  end

  def permitted_params
    params.permit(:id, :stage_type)
  end
end
