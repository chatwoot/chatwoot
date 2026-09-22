class Api::V1::Accounts::MonitorsController < Api::V1::Accounts::EnterpriseAccountsController
  PREVIEW_COOLDOWN = 30.seconds.to_i

  before_action :ensure_enabled
  before_action -> { authorize :report, :view? }
  before_action :check_admin_authorization?, except: [:index, :show, :timeseries]
  before_action :fetch_monitor, except: [:index, :create, :preview, :preview_status]

  rescue_from CustomExceptions::MonitorParametersError do |error|
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def index
    page = params[:page] ? ConversationMonitors::Buckets.integer!(params[:page]) : 1
    raise CustomExceptions::MonitorParametersError, 'invalid_page' unless page.between?(1, 100_000)

    scope = Current.account.conversation_monitors.visible.order(created_at: :desc, id: :desc)
    render json: { payload: scope.offset((page - 1) * 20).limit(20).map { |monitor| serialize(monitor) },
                   meta: { total_count: scope.count, page: page, configured: ConversationMonitors::Configuration.configured?, usage: usage } }
  end

  def show
    render json: serialize(@monitor).merge(usage: usage)
  end

  def create
    return render json: { error: 'not_configured' }, status: :service_unavailable unless ConversationMonitors::Configuration.configured?

    attributes = create_params
    Current.account.with_lock do
      raise CustomExceptions::MonitorParametersError, 'monitor_limit' if limit_reached?

      @monitor = Current.account.conversation_monitors.create!(attributes.merge(
                                                                 creator: Current.user, history_since: 7.days.ago,
                                                                 model: ConversationMonitors::Configuration.model,
                                                                 threshold: ConversationMonitors::Configuration::THRESHOLD
                                                               ))
      @scan = @monitor.scans.create!(kind: 'initial', started_at: @monitor.history_since, ended_at: @monitor.created_at,
                                     collection_version: @monitor.collection_version)
    end
    ConversationMonitors::Scheduler.start_scan(@scan.id)
    render json: serialize(@monitor), status: :created
  end

  def update
    attributes = update_params
    version = ConversationMonitors::Buckets.integer!(params[:collection_version]) if attributes.key?('condition')
    ConversationMonitors::Update.new(@monitor, attributes, collection_version: version).perform
    render json: serialize(@monitor)
  end

  def preview
    condition = preview_condition
    key = "conversation_monitors:preview_limit:#{Current.account.id}:#{Current.user.id}"
    unless Redis::Alfred.set(key, '1', nx: true, ex: PREVIEW_COOLDOWN)
      retry_after = [Redis::Alfred.ttl(key), 1].max
      response.set_header('Retry-After', retry_after.to_s)
      return render json: { error: 'preview_rate_limit', retry_after: retry_after }, status: :too_many_requests
    end

    token = SecureRandom.hex(16)
    ConversationMonitors::PreviewJob.write(ConversationMonitors::PreviewJob.cache_key(Current.account.id, Current.user.id, token),
                                           { status: 'pending', condition: condition })
    ConversationMonitors::PreviewJob.perform_later(Current.account.id, Current.user.id, token)
    render json: { token: token, status: 'pending', retry_after: PREVIEW_COOLDOWN }, status: :accepted
  end

  def preview_status
    key = ConversationMonitors::PreviewJob.cache_key(Current.account.id, Current.user.id, params[:token])
    result = ConversationMonitors::PreviewJob.read(key)
    return head :not_found unless result

    render json: serialize_preview(result)
  end

  def destroy
    @monitor.with_lock { @monitor.update!(deleted_at: Time.current, data_revision: @monitor.data_revision + 1) }
    head :no_content
  end

  def timeseries
    @monitor.with_lock do
      render json: ConversationMonitors::Report.new(@monitor, params).timeseries.merge(monitor: serialize(@monitor), usage: usage)
    end
  end

  def conversations
    @monitor.with_lock do
      if ConversationMonitors::Buckets.integer!(params[:data_revision]) != @monitor.data_revision
        return render json: { error: 'data_changed' }, status: :conflict
      end

      render json: ConversationMonitors::Report.new(@monitor, params).conversations
    end
  end

  def retry_evaluations
    raise CustomExceptions::MonitorParametersError, 'monitor_paused' if @monitor.paused_at

    raise CustomExceptions::MonitorParametersError, 'monitor_changed' unless @monitor.collecting?

    ConversationMonitors::RetryJob.perform_later(@monitor.id)
    head :accepted
  end

  def resume
    version = ConversationMonitors::Buckets.integer!(params[:collection_version])
    ConversationMonitors::Resume.new(@monitor, mode: params[:mode], collection_version: version).perform
    render json: serialize(@monitor)
  end

  private

  def usage
    @usage ||= ConversationMonitors::Usage.new(Current.account.id).snapshot
  end

  def serialize_preview(result)
    payload = result.except(:condition, :conversation_ids)
    return payload unless result[:status] == 'complete'

    records = Current.account.conversations.where(id: result.fetch(:conversation_ids)).includes(:contact, :inbox, :assignee).order(id: :desc).to_a
    serializer = V2::Reports::DrilldownRecordSerializer.new(Current.account, 'conversations_count', false, records)
    payload.merge(payload: records.map { |record| serializer.serialize(record) })
  end

  def preview_condition
    condition = params[:condition]
    unless condition.is_a?(String) && condition.strip.present? && condition.length <= 2000
      raise CustomExceptions::MonitorParametersError, 'invalid_parameters'
    end

    condition.strip
  end

  def update_params
    attributes = params.permit(:name, :condition, :paused).to_h
    valid_text = { 'name' => 100, 'condition' => 2000 }.slice(*params.keys).all? do |key, limit|
      valid_text_parameter?(key, limit)
    end
    valid_state = params.slice(:paused).values.all?(true)
    raise CustomExceptions::MonitorParametersError, 'invalid_parameters' unless attributes.any? && valid_text && valid_state

    attributes.transform_values { |value| value.is_a?(String) ? value.strip : value }
  end

  def valid_text_parameter?(key, limit)
    value = params[key]
    value.is_a?(String) && value.strip.present? && value.length <= limit
  end

  def ensure_enabled
    head :forbidden unless ConversationMonitors::Configuration.enabled?(Current.account)
  end

  def fetch_monitor
    @monitor = Current.account.conversation_monitors.visible.find(params[:id])
  end

  def serialize(monitor)
    ConversationMonitors::Presenter.new(monitor).as_json
  end

  def limit_reached?
    Current.account.conversation_monitors.active.count >= ConversationMonitors::Configuration.max_monitors
  end

  def create_params
    attributes = params.permit(:name, :condition).to_h
    valid = { 'name' => 100, 'condition' => 2000 }.all? { |key, limit| valid_text_parameter?(key, limit) }
    raise CustomExceptions::MonitorParametersError, 'invalid_parameters' unless valid

    attributes.transform_values(&:strip)
  end
end
