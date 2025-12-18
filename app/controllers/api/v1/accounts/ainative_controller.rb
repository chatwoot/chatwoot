# frozen_string_literal: true

class Api::V1::Accounts::AinativeController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  # GET /api/v1/accounts/:account_id/ainative
  # Get AINative configuration status for the account
  def show
    @ainative_config = {
      configured: Current.account.ainative_configured?,
      project_id: Current.account.ainative_project_id,
      settings: Current.account.ainative_settings || {},
      features_available: features_available?
    }

    render json: @ainative_config
  end

  # POST /api/v1/accounts/:account_id/ainative/provision
  # Manually trigger AINative project provisioning
  def provision
    if Current.account.ainative_configured?
      return render json: {
        error: 'AINative project already configured',
        project_id: Current.account.ainative_project_id
      }, status: :unprocessable_entity
    end

    unless master_api_key_configured?
      return render json: {
        error: 'AINative integration not available. Contact your system administrator.'
      }, status: :service_unavailable
    end

    Zerodb::ProjectProvisionJob.perform_later(Current.account.id)

    render json: {
      message: 'AINative project provisioning started',
      status: 'pending'
    }, status: :accepted
  end

  # PATCH /api/v1/accounts/:account_id/ainative
  # Update AINative settings
  def update
    unless Current.account.ainative_configured?
      return render json: {
        error: 'AINative project not configured. Please provision a project first.'
      }, status: :unprocessable_entity
    end

    Current.account.ainative_settings.merge!(ainative_settings_params)
    Current.account.save!

    render json: {
      message: 'AINative settings updated successfully',
      settings: Current.account.ainative_settings
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /api/v1/accounts/:account_id/ainative
  # Deprovision AINative project
  def destroy
    unless Current.account.ainative_configured?
      return render json: {
        error: 'No AINative project configured'
      }, status: :unprocessable_entity
    end

    begin
      Zerodb::ProjectProvisionService.new(Current.account).deprovision!
      render json: {
        message: 'AINative project deprovisioned successfully'
      }
    rescue Zerodb::ProjectProvisionService::ProvisionError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/accounts/:account_id/ainative/status
  # Get detailed status including vector counts, memory usage, etc.
  def status
    unless Current.account.ainative_configured?
      return render json: {
        error: 'AINative project not configured'
      }, status: :unprocessable_entity
    end

    begin
      client = Current.account.ainative_client
      # This would call the ZeroDB API to get project stats
      # For now, just return basic info
      render json: {
        configured: true,
        project_id: Current.account.ainative_project_id,
        settings: Current.account.ainative_settings,
        features: {
          semantic_search: Current.account.ainative_settings.dig('features', 'semantic_search'),
          smart_suggestions: Current.account.ainative_settings.dig('features', 'smart_suggestions'),
          agent_memory: Current.account.ainative_settings.dig('features', 'agent_memory')
        }
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def ainative_settings_params
    params.permit(
      :embeddings_model,
      :vector_dimensions,
      :auto_indexing,
      features: [:semantic_search, :smart_suggestions, :agent_memory]
    ).to_h
  end

  def master_api_key_configured?
    ENV['ZERODB_MASTER_API_KEY'].present?
  end

  def features_available?
    master_api_key_configured?
  end

  def check_authorization
    authorize Current.account, policy_class: AccountPolicy
  end
end
