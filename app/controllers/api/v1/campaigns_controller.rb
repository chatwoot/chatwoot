# frozen_string_literal: true

# app/controllers/api/v1/campaigns_controller.rb
class Api::V1::CampaignsController < Api::V1::BaseController
  before_action :set_campaign, only: %i[show update destroy execute]

  # GET /api/v1/accounts/:account_id/campaigns
  def index
    scope = current_account.campaigns

    # simple filtering
    scope = scope.where(campaign_status: params[:status]) if params[:status].present?
    scope = scope.where(campaign_type:   params[:type])   if params[:type].present?
    scope = scope.where(inbox_id:        params[:inbox_id]) if params[:inbox_id].present?
    if params[:q].present?
      q = params[:q].to_s
      scope = scope.where("title ILIKE :q OR COALESCE(description, '') ILIKE :q", q: "%#{q}%")
    end

    scope = scope.order(created_at: :desc)

    # pagination
    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i
    per_page = 1 if per_page < 1
    per_page = 100 if per_page > 100

    total = scope.count
    items = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      data: items.as_json(only: %i[
        id title message inbox_id campaign_type campaign_status scheduled_at created_at updated_at
      ]),
      meta: { pagination: { page:, per_page:, total: } }
    }
  end

  # GET /api/v1/accounts/:account_id/campaigns/:id
  def show
    render json: { data: @campaign.as_json }
  end

  # POST /api/v1/accounts/:account_id/campaigns
  def create
    record = current_account.campaigns.new(campaign_params)
    if record.save
      render json: { data: record.as_json }, status: :created
    else
      render json: {
        error: { code: 'validation_error', message: 'Invalid', details: record.errors }
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/accounts/:account_id/campaigns/:id
  def update
    # prevent manual direct status flips via update
    attrs = campaign_params.except(:campaign_status)

    if @campaign.update(attrs)
      render json: { data: @campaign.as_json }
    else
      render json: {
        error: { code: 'validation_error', message: 'Invalid', details: @campaign.errors }
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/campaigns/:id
  def destroy
    if @campaign.respond_to?(:completed?) && @campaign.completed?
      render json: {
        error: { code: 'immutable_state', message: 'Cannot delete a completed campaign' }
      }, status: :conflict
    else
      @campaign.destroy!
      head :no_content
    end
  end

  # POST /api/v1/accounts/:account_id/campaigns/:id/execute
  def execute
    @campaign.trigger! if @campaign.respond_to?(:trigger!)
    render json: { data: { id: @campaign.id, campaign_status: @campaign.campaign_status } }, status: :accepted
  end

  private

  def set_campaign
    @campaign = current_account.campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(
      :title,
      :message,
      :inbox_id,
      :scheduled_at,
      :description,
      :sender_id,
      :trigger_only_during_business_hours,
      :campaign_type,
      :campaign_status, # filtered out on update above
      audience: {},
      template_params: {},
      trigger_rules: {}
    )
  end
end
