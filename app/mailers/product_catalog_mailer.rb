class ProductCatalogMailer < ApplicationMailer
  include FrontendUrlsHelper

  def export_completed(bulk_request)
    return unless smtp_config_set_or_development?

    @user = bulk_request.user
    @bulk_request = bulk_request
    @total_records = bulk_request.total_records
    @file_name = bulk_request.file_name

    subject = "#{@user.available_name}, Your product catalog export is ready!"
    @action_url = frontend_url("accounts/#{bulk_request.account_id}/knowledge-base/products")

    send_mail_with_liquid(to: @user.email, subject: subject)
  end

  private

  def liquid_droppables
    super.merge({
      user: @user
    })
  end

  def liquid_locals
    super.merge({
      total_records: @total_records,
      file_name: @file_name
    })
  end
end
