class Api::V1::Accounts::PortalsController < Api::V1::Accounts::BaseController
  include ::FileTypeHelper

  before_action :fetch_portal, except: [:index, :create]
  before_action :check_authorization
  before_action :set_current_page, only: [:index]

  def index
    @portals = Current.account.portals
  end

  def add_members
    agents = Current.account.agents.where(id: portal_member_params[:member_ids])
    @portal.members << agents
  end

  def show; end

  def create
    @portal = Current.account.portals.build(portal_params)
    @portal.save!
    process_attached_logo
  end

  def update
    ActiveRecord::Base.transaction do
      @portal.update!(portal_params) if params[:portal].present?
      process_attached_logo
    rescue StandardError => e
      Rails.logger.error e
      render json: { error: @portal.errors.messages }.to_json, status: :unprocessable_entity
    end
  end

  def destroy
    @portal.destroy!
    head :ok
  end

  def archive
    @portal.update(archive: true)
    head :ok
  end

  def process_attached_logo
    @portal.logo.attach(params[:logo])
  end

  private

  def fetch_portal
    @portal = Current.account.portals.find_by(slug: permitted_params[:id])
  end

  def permitted_params
    params.permit(:id)
  end

  def portal_params
    params.require(:portal).permit(
      :account_id, :color, :custom_domain, :header_text, :homepage_link, :name, :page_title, :slug, :archived, { config: [:default_locale,
                                                                                                                          { allowed_locales: [] }] }
    )
  end

  def portal_member_params
    params.require(:portal).permit(:account_id, member_ids: [])
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
