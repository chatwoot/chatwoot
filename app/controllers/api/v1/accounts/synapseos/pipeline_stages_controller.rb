class Api::V1::Accounts::Synapseos::PipelineStagesController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :ensure_defaults
  before_action :fetch_stage, only: [:show, :update, :destroy]

  def index
    @stages = scope.ordered
  end

  def show; end

  def create
    @stage = scope.new(stage_params)
    @stage.position ||= (scope.maximum(:position) || -1) + 1
    @stage.save!
  end

  def update
    @stage.update!(stage_params)
  end

  def destroy
    @stage.destroy!
    head :ok
  end

  def templates
    render json: ::Synapseos::PipelineTemplates.list
  end

  def apply_template
    key = params[:template_key].presence
    raise ArgumentError, "template_key is required" if key.nil?

    ::Synapseos::PipelineTemplates.apply(Current.account, key)
    @stages = scope.ordered
    render :index
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def reorder
    ensure_defaults
    ActiveRecord::Base.transaction do
      Array(params[:stages]).each do |entry|
        next if entry[:id].blank?

        scope.where(id: entry[:id]).update_all(position: entry[:position].to_i)
      end
    end
    @stages = scope.ordered
    render :index
  end

  private

  def scope
    ::Synapseos::PipelineStage.where(account_id: Current.account.id)
  end

  def fetch_stage
    @stage = scope.find(params[:id])
  end

  def stage_params
    params.require(:pipeline_stage).permit(:name, :color, :position, :stage_type, :description)
  end

  def ensure_defaults
    ::Synapseos::EnsureDefaultStagesService.new(Current.account).call
  end

  def check_authorization
    authorize(User, :index?)
  end
end
