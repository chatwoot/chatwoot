# frozen_string_literal: true

class SuperAdmin::Synapseos::ClientsController < SuperAdmin::ApplicationController
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
end
