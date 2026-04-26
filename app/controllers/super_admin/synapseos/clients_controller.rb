# frozen_string_literal: true

class SuperAdmin::Synapseos::ClientsController < SuperAdmin::ApplicationController
  include Synapseos::AgenticPayloadBuilder

  helper Synapseos::SchemaFormHelper

  before_action :ensure_agentic_configured

  def index
    result = agentic.clients(account_id: params[:account_id])

    if result.failure?
      @error = result
      @clients = []
    else
      @clients = Array(result.data)
    end

    fetch_templates_for_index
  end

  def show
    client_result = agentic.client(params[:slug])

    if client_result.failure? && client_result.kind == :not_found
      render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
      return
    end

    if client_result.failure?
      redirect_to super_admin_synapseos_clients_path, alert: humanize_agentic_error(client_result)
      return
    end

    @client = client_result.data

    templates_result = agentic.templates
    @templates = templates_result.ok? ? (templates_result.data['agents'] || {}) : {}
  end

  helper_method :humanize_agentic_error

  def new
    load_form_metadata
    @client_payload = {}
    @values = {}
    @errors = {}
  end

  # rubocop:disable Rails/I18nLocaleTexts
  def edit
    client_result = agentic.client(params[:slug])

    if client_result.failure? && client_result.kind == :not_found
      render file: Rails.public_path.join('404.html'), status: :not_found, layout: false
      return
    end

    @client_payload = client_result.data || {}
    @values = @client_payload
    load_form_metadata
    @errors = {}
  end

  def create
    payload = build_payload_from_params(params[:client] || {})
    target_slug = payload['slug'].presence || params[:slug].to_s
    result = agentic.save_client(target_slug, payload)

    if result.ok?
      audit!(action: 'create', slug: target_slug, payload: payload, result: result)
      redirect_to super_admin_synapseos_client_path(slug: target_slug), notice: 'Client created.'
      return
    end

    handle_save_failure(result, payload, target_slug, render_view: :new, audit_action: 'create')
  end

  def update
    payload = build_payload_from_params(params[:client] || {})
    target_slug = params[:slug].to_s
    result = agentic.save_client(target_slug, payload)

    if result.ok?
      audit!(action: 'update', slug: target_slug, payload: payload, result: result)
      redirect_to super_admin_synapseos_client_path(slug: target_slug), notice: 'Client updated.'
      return
    end

    handle_save_failure(result, payload, target_slug, render_view: :edit, audit_action: 'update')
  end

  def destroy
    target_slug = params[:slug].to_s
    result = agentic.delete_client(target_slug)

    if result.ok?
      audit!(action: 'delete', slug: target_slug, result: result)
      redirect_to super_admin_synapseos_clients_path, notice: 'Client deleted.'
      return
    end

    audit!(action: 'delete', slug: target_slug, result: result)
    flash[:error] = destroy_failure_message(result)
    redirect_to super_admin_synapseos_client_path(slug: target_slug)
  end
  # rubocop:enable Rails/I18nLocaleTexts

  private

  def agentic
    Synapseos::Agentic.client
  end

  def ensure_agentic_configured
    Synapseos::Agentic.client
  rescue Synapseos::Agentic::NotConfiguredError
    render :not_configured
  end

  def fetch_templates_for_index
    return if @error.present?

    templates_result = agentic.templates
    @templates = templates_result.ok? ? (templates_result.data['agents'] || {}) : {}
  end

  def humanize_agentic_error(result)
    base_url = Synapseos::Agentic.config[:url]

    case result.kind
    when :agentic_offline
      "The agentic panel is offline. Check that the service is running at #{base_url}."
    when :unauthorized
      'Invalid credentials. Update SYNAPSEOS_AGENTIC_USER/SYNAPSEOS_AGENTIC_PASSWORD in Installation Configs.'
    else
      "Unexpected error: #{result.message}."
    end
  end

  def load_form_metadata
    schema_result = agentic.schema
    templates_result = agentic.templates
    credentials_result = agentic.n8n_credentials

    @schema = schema_result.ok? ? schema_result.data : {}
    @templates = templates_result.ok? ? (templates_result.data['agents'] || {}) : {}
    @credentials = credentials_result.ok? ? Array(credentials_result.data) : []
  end

  def handle_save_failure(result, payload, target_slug, render_view:, audit_action:)
    audit!(action: audit_action, slug: target_slug, payload: payload, result: result)

    @values = payload
    @client_payload = payload
    load_form_metadata

    if result.kind == :validation
      @errors = flatten_validation_errors(result.details)
    else
      @errors = {}
      flash.now[:error] = "Save failed: #{result.message}"
    end

    render render_view, status: :unprocessable_entity
  end

  # Converts FastAPI's `[{loc: ["body", "credentials", "postgres", "id"], msg: "field required"}, ...]`
  # into `{"credentials.postgres.id" => "field required"}`. Drops the leading "body" segment.
  def flatten_validation_errors(details)
    return {} unless details.is_a?(Hash) && details['detail'].is_a?(Array)

    details['detail'].each_with_object({}) do |entry, acc|
      flatten_validation_entry(entry, acc)
    end
  end

  def flatten_validation_entry(entry, acc)
    return unless entry.is_a?(Hash)

    loc = Array(entry['loc'])
    loc = loc.drop(1) if loc.first == 'body'
    key = loc.map(&:to_s).join('.')
    acc[key] = entry['msg'].to_s if key.present?
  end

  def destroy_failure_message(result)
    return 'Client is deployed. Run undeploy first.' if result.kind == :conflict

    "Could not delete client: #{result.message}"
  end

  def audit!(action:, slug:, result:, payload: nil)
    SynapseosAgenticDeploymentLog.create!(
      slug: slug,
      account_id: payload.is_a?(Hash) ? payload['chatwoot_account_id'] : nil,
      super_admin_id: current_super_admin&.id,
      action: action,
      status: result.ok? ? 'success' : 'failure',
      payload: payload,
      result_summary: result.ok? ? result.data : result.details,
      error_message: result.ok? ? nil : result.message
    )
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("[SynapseosAgenticDeploymentLog] could not write audit row: #{e.message}")
  end
end
