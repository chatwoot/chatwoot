class ReportNotifications::CustomReportMailer < ApplicationMailer
  def custom_report(csv_url, start_date, end_date, grouped_by, email)
    return unless smtp_config_set_or_development?

    subject = "#{grouped_by.capitalize} Report from #{start_date} to #{end_date}"
    @action_url = csv_url
    @meta = {
      start_date: start_date,
      end_date: end_date,
      grouped_by: grouped_by
    }

    recipients = [email]
    recipients += ['jaideep+chatwootreports@bitespeed.co', 'aryanm@bitespeed.co']

    send_mail_with_liquid(to: recipients, subject: subject) and return
  end

  private

  def liquid_droppables
    super.merge({
                  meta: @meta
                })
  end
end
