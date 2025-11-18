class Api::V1::Accounts::SalesPipelineStagesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :fetch_sales_pipeline
  before_action :fetch_stage, except: [:index, :create]
  before_action :check_authorization

  def index
    @stages = @sales_pipeline.sales_pipeline_stages.includes(:label)
  end

  def show; end

  def create
    ActiveRecord::Base.transaction do
      label = current_account.labels.create!(
        title: stage_params[:name],
        color: stage_params[:color],
        description: "Estágio do pipeline de vendas: #{stage_params[:name]}"
      )

      @stage = @sales_pipeline.sales_pipeline_stages.create!(
        stage_params.merge(label_id: label.id)
      )
    end
  end

  def update
    ActiveRecord::Base.transaction do
      @stage.update!(stage_params)
    end
  end

  def destroy
    migration_stage_id = params.dig(:stage, :migration_stage_id)

    ActiveRecord::Base.transaction do
      if migration_stage_id.present?
        migrate_conversations!(migration_stage_id)
      else
        validate_destruction!
      end

      @stage.destroy!
    end

    head :ok
  end

  def reorder
    stage_orders = params.require(:stages).map { |s| [s[:id], s[:position]] }.to_h

    ActiveRecord::Base.transaction do
      stage_orders.each do |stage_id, position|
        stage = @sales_pipeline.sales_pipeline_stages.find(stage_id)
        stage.update!(position: position)
      end
    end

    head :ok
  end

  private

  def fetch_sales_pipeline
    @sales_pipeline = current_account.sales_pipelines.first_or_create!
  end

  def fetch_stage
    @stage = @sales_pipeline.sales_pipeline_stages.find(params[:id])
  end

  def stage_params
    params.require(:stage).permit(:name, :color, :position, :is_default, :is_closed_won, :is_closed_lost)
  end

  def validate_destruction!
    return if @stage.conversations.empty?

    render json: { 
      error: 'Não é possível excluir estágio com conversas ativas',
      conversations_count: @stage.conversations.count
    }, status: :unprocessable_entity
  end

  def migrate_conversations!(migration_stage_id)
    migration_stage = @sales_pipeline.sales_pipeline_stages.find(migration_stage_id)
    manager = SalesPipeline::ConversationStageManager

    @stage.conversations.find_each do |conversation|
      stage_manager = manager.new(conversation: conversation, account: current_account)
      stage_manager.update_stage!(migration_stage)
    end
  end
end