class Api::V1::Accounts::PortalsController < Api::V1::Accounts::BaseController
  include ::FileTypeHelper

  before_action :fetch_portal, except: [:index, :create, :attach_file]
  before_action :check_authorization
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
    blob_id = params[:blob_id]
    blob = ActiveStorage::Blob.find_by(id: blob_id)
    @portal.logo.attach(blob)
  end

  def attach_file
    file_blob = ActiveStorage::Blob.create_and_upload!(
      key: nil,
      io: params[:logo].tempfile,
      filename: params[:logo].original_filename,
      content_type: params[:logo].content_type
    )
    render json: { blob_key: file_blob.key, blob_id: file_blob.id }
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
