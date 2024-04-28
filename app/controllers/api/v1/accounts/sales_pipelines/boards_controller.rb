class Api::V1::Accounts::SalesPipelines::BoardsController < Api::V1::Accounts::BaseController
  def index
    @boards = Current.account.stages.where(disabled: false).order(:id)
    render json: @boards.to_json
  end

  def search
    stage_type = Stage::STAGE_TYPE_MAPPING[params[:stage_type]]
    both_type = Stage::STAGE_TYPE_MAPPING['both']
    @contacts = Current.account.contacts.joins(:stage)
                       .where("stages.stage_type = #{stage_type} or stages.stage_type = #{both_type} or #{stage_type} = #{both_type}")
                       .select(:id, :name, :email, :phone_number, :created_at, :last_activity_at, 'stages.code')
                       .order(last_activity_at: :desc)
    render json: @contacts.to_json
  end
end
