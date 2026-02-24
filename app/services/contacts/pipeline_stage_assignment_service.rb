class Contacts::PipelineStageAssignmentService
  def initialize(contact:)
    @contact = contact
    @account = contact.account
  end

  def perform
    current_labels = @contact.label_list
    sync_pipeline_stages(current_labels)
  end

  private

  def sync_pipeline_stages(current_labels)
    label_records = @account.labels.where(title: current_labels).includes(:pipeline_stages)
    labels_with_pipelines = label_records.select { |l| l.pipeline_stages.any? }

    active_stage_ids = labels_with_pipelines.flat_map do |label|
      ensure_stage_for_label(label)
    end

    # Remove stages for labels that were removed
    @contact.contact_pipeline_stages
            .where.not(pipeline_stage_id: active_stage_ids)
            .joins(:pipeline_stage)
            .where.not(pipeline_stages: { label_id: labels_with_pipelines.map(&:id) })
            .destroy_all
  end

  def ensure_stage_for_label(label)
    stage_ids = label.pipeline_stages.pluck(:id)
    existing = @contact.contact_pipeline_stages.where(pipeline_stage_id: stage_ids)

    if existing.any?
      existing.pluck(:pipeline_stage_id)
    else
      first_stage = label.pipeline_stages.first
      return [] unless first_stage

      @contact.contact_pipeline_stages.create!(
        pipeline_stage: first_stage,
        account: @account
      )
      [first_stage.id]
    end
  end
end
