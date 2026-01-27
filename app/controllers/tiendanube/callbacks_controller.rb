# app/controllers/tiendanube/callbacks_controller.rb
class Tiendanube::CallbacksController < ApplicationController
  include Tiendanube::IntegrationHelper

  def show
    account_id = session.delete(:tiendanube_account_id)
    raise 'Missing account context' if account_id.blank?

    account = Account.find(account_id)

    create_hook!(
      account: account,
      code: params[:code]
    )

    redirect_to integration_url(account), allow_other_host: true
  rescue StandardError => e
    Rails.logger.error("Tiendanube callback error: #{e.message}")
    redirect_to error_url, allow_other_host: true
  end

  private

  def integration_url(account)
    "#{ENV.fetch('FRONTEND_URL')}/app/accounts/#{account.id}/settings/integrations/tiendanube"
  end

  def error_url
    ENV.fetch('FRONTEND_URL')
  end
end
