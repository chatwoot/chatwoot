class Api::V1::Accounts::Synapseos::PipelineController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    ::Synapseos::EnsureDefaultStagesService.new(Current.account).call
    @stages = ::Synapseos::PipelineStage.where(account_id: Current.account.id).ordered
    @leads = enriched_leads
  end

  private

  def enriched_leads
    leads = ::Synapseos::Lead
              .where(account_id: Current.account.id)
              .includes(:conversation, :contact, :pipeline_stage)
    leads = leads.where(pipeline_stage_id: params[:stage_id]) if params[:stage_id].present?
    leads.order(updated_at: :desc).limit(500)
  end

  def check_authorization
    authorize(User, :index?)
  end
end
