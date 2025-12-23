# frozen_string_literal: true

class Api::V1::BrandingController < Api::BaseController
  before_action :check_admin_authorization
  before_action :set_branding_config

  def show
    render json: @branding_config.as_json(only: [:id, :brand_name, :brand_website, :support_email, :created_at, :updated_at],
                                          methods: [:logo_main_url, :logo_compact_url, :favicon_url, :apple_touch_icon_url])
  end

  def update
    # Handle file uploads first (before validation)
    handle_file_uploads
    
    # Then update text fields
    if @branding_config.update(branding_params)
      # Reload to get updated URLs
      @branding_config.reload
      render json: @branding_config.as_json(only: [:id, :brand_name, :brand_website, :support_email, :created_at, :updated_at],
                                            methods: [:logo_main_url, :logo_compact_url, :favicon_url, :apple_touch_icon_url])
    else
      render json: { errors: @branding_config.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def check_admin_authorization
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def set_branding_config
    @branding_config = BrandingConfig.instance
  end

  def branding_params
    params.permit(:brand_name, :brand_website, :support_email)
  end

  def handle_file_uploads
    # Handle file uploads from multipart form data
    # ActiveStorage automatically replaces old attachments when attaching new ones
    if params[:logo_main].present? && params[:logo_main].is_a?(ActionDispatch::Http::UploadedFile)
      @branding_config.logo_main.attach(params[:logo_main])
    end
    if params[:logo_compact].present? && params[:logo_compact].is_a?(ActionDispatch::Http::UploadedFile)
      @branding_config.logo_compact.attach(params[:logo_compact])
    end
    if params[:favicon].present? && params[:favicon].is_a?(ActionDispatch::Http::UploadedFile)
      @branding_config.favicon.attach(params[:favicon])
    end
    if params[:apple_touch_icon].present? && params[:apple_touch_icon].is_a?(ActionDispatch::Http::UploadedFile)
      @branding_config.apple_touch_icon.attach(params[:apple_touch_icon])
    end
  end
end

