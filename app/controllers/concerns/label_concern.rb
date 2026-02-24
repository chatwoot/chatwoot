module LabelConcern
  def create
    model.update_labels(permitted_params[:labels])
    sync_pipeline_stages if model.is_a?(Contact)
    @labels = model.label_list
  end

  def index
    @labels = model.label_list
  end

  private

  def sync_pipeline_stages
    Contacts::PipelineStageAssignmentService.new(contact: model).perform
  end
end
