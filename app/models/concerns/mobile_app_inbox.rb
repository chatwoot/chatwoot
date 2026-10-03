module MobileAppInbox
  extend ActiveSupport::Concern

  included do
    has_one :sdk_app, dependent: :destroy
    after_create :create_mobile_sdk_app, if: :mobile_app?
    after_update :update_mobile_sdk_app_name, if: :mobile_app?
  end

  def mobile_app?
    channel_type == 'Channel::MobileApp'
  end

  private

  def create_mobile_sdk_app
    create_sdk_app!(account: account, name: name)
  end

  def update_mobile_sdk_app_name
    sdk_app.update!(name: name) if saved_change_to_name?
  end
end
