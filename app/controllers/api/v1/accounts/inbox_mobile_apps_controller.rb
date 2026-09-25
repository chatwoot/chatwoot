class Api::V1::Accounts::InboxMobileAppsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :set_inbox

  def show
    app = @inbox.mobile_app
    render json: app ? app_payload(app) : { app: nil, devices: [] }
  end

  def update
    unless Chatwoot.encryption_configured?
      render_could_not_create_error('Configure Active Record encryption before saving push credentials')
      return
    end

    attributes = params.require(:mobile_app)
    unless attributes.is_a?(ActionController::Parameters) && attributes.values.all?(String)
      render_could_not_create_error('Mobile app fields must be strings')
      return
    end

    app = @inbox.mobile_app || @inbox.build_mobile_app
    app.update!(attributes.permit(:name, :bundle_id, :team_id, :key_id, :private_key))
    render json: app_payload(app)
  end

  def destroy
    @inbox.mobile_app&.destroy!
    head :no_content
  end

  def test_notification
    app = @inbox.mobile_app
    raise ActiveRecord::RecordNotFound unless app

    device = app.mobile_push_devices.where(invalidated_at: nil).find(params[:device_id])
    delivery = device.mobile_push_deliveries.create!
    MobilePush::DeliveryJob.perform_later(delivery.id)
    render json: { id: delivery.id, status: delivery.status }, status: :accepted
  end

  private

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    raise ActiveRecord::RecordNotFound unless @inbox.web_widget?
  end

  def app_payload(app)
    {
      app: app.slice(:id, :name, :bundle_id, :team_id, :key_id).merge(credentials_configured: true),
      devices: app.mobile_push_devices.order(registered_at: :desc).limit(50).map do |device|
        device.slice(:id, :name, :environment, :registered_at, :invalidated_at).merge(
          last_delivery: device.mobile_push_deliveries.order(id: :desc).first&.slice(:status, :reason, :apns_id, :updated_at)
        )
      end
    }
  end
end
