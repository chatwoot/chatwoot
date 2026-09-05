class Reports::AllMetricsMailer < ApplicationMailer
  def report_ready(user_email, file_path, filename, report_type)
    return unless smtp_config_set_or_development?

    @filename = filename
    @report_type = report_type.to_s.humanize

    attachments[filename] = File.read(file_path)

    subject = "Your #{@report_type} report is ready"

    mail(
      to: user_email,
      subject: subject
    )
  end

  def report_generation_failed(user_email, report_type, error_message = nil)
    return unless smtp_config_set_or_development?

    @report_type = report_type.to_s.humanize
    @error_message = error_message

    subject = "Failed to generate #{@report_type} report"

    send_mail_with_liquid(
      to: user_email,
      subject: subject,
      template_path: 'mailers/reports/all_metrics_mailer',
      template_name: 'report_generation_failed'
    ) do
      {
        report_type: @report_type,
        error_message: @error_message
      }
    end
  end

  private

  def liquid_droppables
    {
      account: Current.account
    }
  end

  def liquid_locals
    {
      global_config: GlobalConfig.get('BRAND_NAME', 'BRAND_URL'),
      filename: @filename,
      report_type: @report_type,
      error_message: @error_message
    }
  end
end
