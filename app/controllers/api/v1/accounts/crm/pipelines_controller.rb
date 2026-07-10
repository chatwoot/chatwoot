class Api::V1::Accounts::Crm::PipelinesController < Api::V1::Accounts::Crm::BaseController
  before_action :fetch_pipeline, only: [:show, :update, :destroy]

  def index
    authorize ::Crm::Pipeline
    @pipelines = policy_scope(::Crm::Pipeline).active.order(:position, :id)
    @pipelines_count = @pipelines.count
  end

  def show; end

  def create
    @pipeline = Current.account.crm_pipelines.new(pipeline_params)
    @pipeline.created_by = Current.user
    authorize @pipeline
    @pipeline.save!
    update_goal!
    render :show, status: :created
  end

  def update
    @pipeline.update!(pipeline_params)
    update_goal!
    update_meta_sync!
    update_google_sync!
    render :show
  end

  def destroy
    @pipeline.archived!
    render :show
  end

  private

  def fetch_pipeline
    @pipeline = policy_scope(::Crm::Pipeline).find(params[:id])
    authorize @pipeline
  end

  def pipeline_params
    parameter_set(:pipeline).permit(:name, :description, :status, :is_default, :position, metadata: {})
  end

  # Monthly sales target lives in metadata['goals'] and is merged in separately
  # so it never clobbers metadata['ai'] (pipeline AI settings).
  def update_goal!
    goal = params.dig(:pipeline, :goal)
    return if goal.nil?

    metadata = (@pipeline.metadata || {}).deep_dup
    target = goal[:monthly_target_cents].to_i
    if target.positive?
      metadata['goals'] = {
        'monthly_target_cents' => target,
        'currency' => (goal[:currency].presence || 'BRL').to_s.upcase
      }
    else
      metadata.delete('goals')
    end
    @pipeline.update!(metadata: metadata)
  end

  # Meta CAPI sync config lives in metadata['meta_sync'] and is merged in
  # separately so it never clobbers metadata['ai'] or metadata['goals'].
  def update_meta_sync!
    meta_sync = params.dig(:pipeline, :meta_sync)
    return if meta_sync.nil?

    bool = ActiveModel::Type::Boolean.new
    metadata = (@pipeline.metadata || {}).deep_dup
    metadata['meta_sync'] = {
      'enabled' => bool.cast(meta_sync[:enabled]) || false,
      'events' => {
        'won' => bool.cast(meta_sync.dig(:events, :won)) || false,
        'lost' => bool.cast(meta_sync.dig(:events, :lost)) || false,
        'moved' => bool.cast(meta_sync.dig(:events, :moved)) || false
      },
      'dataset_id' => meta_sync[:dataset_id].presence
    }
    @pipeline.update!(metadata: metadata)
  end

  # Google offline conversions config lives in metadata['google_sync'] and is merged
  # in separately so it never clobbers metadata['ai'], 'goals' or 'meta_sync'.
  def update_google_sync!
    google_sync = params.dig(:pipeline, :google_sync)
    return if google_sync.nil?

    bool = ActiveModel::Type::Boolean.new
    metadata = (@pipeline.metadata || {}).deep_dup
    metadata['google_sync'] = {
      'enabled' => bool.cast(google_sync[:enabled]) || false,
      'events' => {
        'won' => bool.cast(google_sync.dig(:events, :won)) || false,
        'lost' => bool.cast(google_sync.dig(:events, :lost)) || false,
        'moved' => bool.cast(google_sync.dig(:events, :moved)) || false
      },
      'conversion_names' => {
        'won' => google_sync.dig(:conversion_names, :won).presence
      }.compact
    }
    @pipeline.update!(metadata: metadata)
  end
end
