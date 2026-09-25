class Api::V1::Widget::MobilePushDevicesController < Api::V1::Widget::BaseController
  before_action :validate_session
  before_action :validate_device_fields, only: :create
  before_action :validate_ios_configuration, only: :create

  def create
    attributes = params.permit(:platform, :device_token, :environment, :name)
    configuration = @sdk_app

    device = if params.key?(:device_id)
               @contact_inbox.mobile_push_devices.where(sdk_app: configuration).find(params[:device_id])
             else
               configuration.mobile_push_devices.find_or_initialize_by(device_token: attributes[:device_token],
                                                                       environment: attributes[:environment], platform: attributes[:platform])
             end
    if device.persisted? && device.contact_inbox_id != @contact_inbox.id
      render_could_not_create_error('Unregister this device from its previous session before registering it again')
      return
    end

    device.update!(attributes.merge(contact_inbox: @contact_inbox, contact: @contact, registered_at: Time.current, invalidated_at: nil))
    render json: { id: device.id }, status: :created
  end

  def destroy
    @contact_inbox.mobile_push_devices.where(sdk_app: @sdk_app).find(params[:id]).destroy!
    head :no_content
  end

  private

  def validate_ios_configuration
    return if @sdk_app.ios_configuration

    render_could_not_create_error('Configure iOS push notifications for this SDK app first')
  end

  def validate_device_fields
    unless params.permit(:platform, :device_token, :environment, :name).values.all?(String)
      render_could_not_create_error('Device fields must be strings')
      return
    end
    return unless params.key?(:device_id) && !params[:device_id].is_a?(Integer)

    render_could_not_create_error('Device ID must be an integer')
  end

  def validate_session
    raise ActiveRecord::RecordNotFound unless @sdk_app

    return if auth_token_params[:inbox_id] == @web_widget.inbox.id

    render json: { error: 'Invalid customer session' }, status: :unauthorized
  end
end
