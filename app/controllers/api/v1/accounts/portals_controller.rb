require 'resolv'

class Api::V1::Accounts::PortalsController < Api::V1::Accounts::BaseController
  include ::FileTypeHelper

  before_action :fetch_portal, except: [:index, :create, :check]
  before_action :check_authorization, except: [:check]  # Skip check_authorization for the check action
  before_action :set_current_page, only: [:index]

  def index
    @portals = Current.account.portals
  end

  def add_members
    agents = Current.account.agents.where(id: portal_member_params[:member_ids])
    @portal.members << agents
  end

  def show
    @all_articles = @portal.articles
    @articles = @all_articles.search(locale: params[:locale])
  end

  def create
    @portal = Current.account.portals.build(portal_params)
    @portal.custom_domain = parsed_custom_domain
    @portal.save!
    process_attached_logo
  end

  def update
    ActiveRecord::Base.transaction do
      @portal.update!(portal_params) if params[:portal].present?
      # @portal.custom_domain = parsed_custom_domain
      process_attached_logo if params[:blob_id].present?
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

  def logo
    @portal.logo.purge if @portal.logo.attached?
    head :ok
  end

  def process_attached_logo
    blob_id = params[:blob_id]
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    @portal.logo.attach(blob)
  end

  def check
    unless params[:domain].present?
      render json: { message: false, error: 'Domain parameter is missing' }, status: :unprocessable_entity
      return
    end
    current_ip = ENV.fetch('CURRENT_IP', nil)
    if current_ip.nil?
      render json: { message: false, error: 'Current IP is not configured' }, status: :unprocessable_entity
      return
    end
    begin
      domain_ip = Resolv.getaddress(params[:domain])
      if domain_ip == current_ip
        DomainConfigJob.perform_later(params[:domain])
        render json: { message: true }, status: :ok
      else
        render json: { message: false, error: 'Domain not configured' }, status: :unprocessable_entity
      end
    rescue Resolv::ResolvError => e
      render json: { message: false, error: 'Domain could not be resolved' }, status: :unprocessable_entity
    end
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

  def parsed_custom_domain
    domain = URI.parse(@portal.custom_domain)
    domain.is_a?(URI::HTTP) ? domain.host : @portal.custom_domain
  end
end
