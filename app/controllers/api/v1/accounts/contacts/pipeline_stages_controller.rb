class Api::V1::Accounts::Contacts::PipelineStagesController < Api::V1::Accounts::Contacts::BaseController
  before_action :fetch_contact_pipeline_stage, only: [:update]

  def index
    # Lazy sync: ensure contact has pipeline stage assignments for all their labels with pipelines
    Contacts::PipelineStageAssignmentService.new(contact: @contact).perform
    @contact_pipeline_stages = @contact.contact_pipeline_stages.reload.includes(pipeline_stage: :label)
  end

  def update
    new_stage = PipelineStage.find(params[:pipeline_stage_id])
    # Ensure the new stage belongs to the same label
    raise ActiveRecord::RecordNotFound unless new_stage.label_id == @contact_pipeline_stage.pipeline_stage.label_id

    @contact_pipeline_stage.update!(pipeline_stage: new_stage)
    @contact_pipeline_stages = @contact.contact_pipeline_stages.reload.includes(pipeline_stage: :label)
    render :index
  end

  private

  def fetch_contact_pipeline_stage
    @contact_pipeline_stage = @contact.contact_pipeline_stages.find(params[:id])
  end
end
