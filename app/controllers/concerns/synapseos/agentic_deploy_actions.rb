# frozen_string_literal: true

# Deploy / undeploy / build / status / snapshots / restore_snapshot member
# actions for the super-admin agentic clients controller. Synchronous calls —
# the agentic panel returns when the operation completes (30s–2min for deploy);
# we let Rails handle the request timeout and update the status pill on redirect
# via a poll flash that the show view reads.
module Synapseos::AgenticDeployActions
  extend ActiveSupport::Concern

  def deploy
    run_deploy_action(action: 'deploy', success_notice: 'Deploy iniciado. Acompanhe o status abaixo.') do |slug|
      agentic.deploy_client(slug)
    end
  end

  def undeploy
    run_deploy_action(action: 'undeploy', success_notice: 'Undeploy concluído.') do |slug|
      agentic.undeploy_client(slug)
    end
  end

  def build
    run_deploy_action(action: 'build', success_notice: 'Build gerado (preview, sem deploy).') do |slug|
      agentic.build_client(slug)
    end
  end

  def deploy_status
    result = agentic.client(params[:slug])

    if result.failure?
      render json: { status: 'error', error: result.message }, status: :bad_gateway
      return
    end

    data = result.data || {}
    render json: {
      status: data['status'] || (data['deployed'] ? 'deployed' : 'not_deployed'),
      deployed: data['deployed'],
      workflows: data['workflows']
    }
  end

  def snapshots
    result = agentic.snapshots(params[:slug])
    @snapshots = result.ok? ? Array(result.data) : []
    @snapshots_error = result.failure? ? result.message : nil

    respond_to do |format|
      format.html { render :snapshots }
      format.json { render json: @snapshots }
    end
  end

  def restore_snapshot
    target_slug = params[:slug].to_s
    snapshot_id = params[:snapshot_id].to_s
    result = agentic.restore_snapshot(target_slug, snapshot_id)

    audit!(action: 'restore_snapshot', slug: target_slug, payload: { 'snapshot_id' => snapshot_id }, result: result)

    if result.ok?
      redirect_to super_admin_synapseos_client_path(slug: target_slug, tab: 'history'),
                  notice: "Snapshot #{snapshot_id} restaurado."
    else
      flash[:error] = "Restore falhou: #{result.message}"
      redirect_to super_admin_synapseos_client_path(slug: target_slug, tab: 'history')
    end
  end

  private

  def run_deploy_action(action:, success_notice:)
    target_slug = params[:slug].to_s
    result = yield(target_slug)
    audit!(action: action, slug: target_slug, result: result)

    respond_to do |format|
      format.html { redirect_after_deploy(result, target_slug, success_notice) }
      format.json { render_deploy_json(result) }
    end
  end

  def redirect_after_deploy(result, target_slug, success_notice)
    if result.ok?
      flash[:notice] = success_notice
      flash[:poll_status] = true
    else
      flash[:error] = "Falhou: #{result.message}"
    end
    redirect_to super_admin_synapseos_client_path(slug: target_slug)
  end

  def render_deploy_json(result)
    if result.ok?
      render json: { ok: true, data: result.data }
    else
      render json: { ok: false, error: result.message, kind: result.kind }, status: :bad_gateway
    end
  end
end
