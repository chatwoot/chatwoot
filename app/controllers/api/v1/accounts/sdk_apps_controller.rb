class Api::V1::Accounts::SdkAppsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :set_sdk_app, only: [:show, :update, :destroy]
  before_action :validate_attributes, only: [:create, :update]

  def index
    render json: Current.account.sdk_apps.includes(:ios_configuration, :android_configuration).order(:name).map { |app| payload(app) }
  end

  def show
    render json: payload(@sdk_app)
  end

  def create
    @sdk_app = Current.account.sdk_apps.create!(@attributes)
    render json: payload(@sdk_app), status: :created
  end

  def update
    @sdk_app.update!(@attributes)
    render json: payload(@sdk_app)
  end

  def destroy
    @sdk_app.destroy!
    head :no_content
  end

  private

  def set_sdk_app
    @sdk_app = Current.account.sdk_apps.find(params[:id])
  end

  def validate_attributes
    attributes = params.require(:sdk_app)
    unless attributes.is_a?(ActionController::Parameters)
      render_could_not_create_error('SDK app must be an object')
      return
    end

    @attributes = attributes.permit(:name, :inbox_id)
    unless @attributes.except(:inbox_id).values.all?(String) && @attributes[:inbox_id].is_a?(Integer)
      render_could_not_create_error('App fields must be strings and inbox ID must be an integer')
      return
    end

    inbox = Current.account.inboxes.find(@attributes[:inbox_id])
    unless inbox.web_widget?
      render_could_not_create_error('Select a Website inbox')
      return
    end
    assign_push_attributes(attributes)
  end

  def assign_push_attributes(attributes)
    assign_ios_attributes(attributes) if attributes.key?(:ios_configuration)
    return if performed?

    assign_android_attributes(attributes) if attributes.key?(:android_configuration)
  end

  def assign_ios_attributes(attributes)
    ios = attributes[:ios_configuration]
    existing = @sdk_app&.ios_configuration
    if ios.nil?
      remove_ios_configuration(existing)
      return
    end
    unless valid_configuration_attributes?(ios)
      render_could_not_create_error('iOS configuration fields must be strings and enabled must be a boolean')
      return
    end
    unless Chatwoot.encryption_configured?
      render_could_not_create_error('Configure Active Record encryption before saving push credentials')
      return
    end

    @attributes[:ios_configuration_attributes] = ios.permit(:enabled, :bundle_id, :team_id, :key_id, :private_key).to_h
    @attributes[:ios_configuration_attributes][:id] = existing.id if existing
  end

  def remove_ios_configuration(existing)
    return unless existing

    @attributes[:ios_configuration_attributes] = { id: existing.id, _destroy: true }
  end

  def assign_android_attributes(attributes)
    android = attributes[:android_configuration]
    existing = @sdk_app&.android_configuration
    if android.nil?
      remove_android_configuration(existing)
      return
    end
    unless valid_configuration_attributes?(android)
      render_could_not_create_error('Android configuration fields must be strings and enabled must be a boolean')
      return
    end
    unless Chatwoot.encryption_configured?
      render_could_not_create_error('Configure Active Record encryption before saving push credentials')
      return
    end

    @attributes[:android_configuration_attributes] = android.permit(:enabled, :package_name, :project_id, :service_account).to_h
    @attributes[:android_configuration_attributes][:id] = existing.id if existing
  end

  def remove_android_configuration(existing)
    return unless existing

    @attributes[:android_configuration_attributes] = { id: existing.id, _destroy: true }
  end

  def valid_configuration_attributes?(attributes)
    attributes.is_a?(ActionController::Parameters) && attributes.except(:enabled).values.all?(String) &&
      (!attributes.key?(:enabled) || [true, false].include?(attributes[:enabled]))
  end

  def payload(app)
    ios = app.ios_configuration
    app.slice(:id, :app_id, :name, :inbox_id).merge(
      ios_configuration: ios&.slice(:enabled, :bundle_id, :team_id, :key_id)&.merge(credentials_configured: true),
      android_configuration: app.android_configuration&.slice(:enabled, :package_name, :project_id)&.merge(credentials_configured: true)
    )
  end
end
