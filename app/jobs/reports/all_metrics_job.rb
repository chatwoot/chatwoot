class Reports::AllMetricsJob < ApplicationJob
  queue_as :default

  def perform(account_id, user_id, params = {})
    setup_account_and_user(account_id, user_id)

    format = params[:format] || 'csv'
    email = params[:email] || @user.email
    report_type = 'all_conversation_metrics'
    filter_params = params.except(:format, :email, :_aj_symbol_keys)

    generate_and_send_report(format, email, report_type, filter_params)
  end

  private

  def setup_account_and_user(account_id, user_id)
    @account = Account.find(account_id)
    @user = User.find(user_id)
    Current.account = @account
  end

  def generate_and_send_report(format, email, report_type, filter_params)
    file_path = nil

    begin
      @report_data = V2::Reports::AllConversationMetricsBuilder.new(@account, filter_params).build

      file_path = generate_report_file(format)
      filename = "#{report_type}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.#{format}"

      Reports::AllMetricsMailer.report_ready(email, file_path, filename, report_type).deliver_now

      Rails.logger.info "Report email sent to #{email}"

    rescue StandardError => e
      Rails.logger.error "Failed to generate report: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      Reports::AllMetricsMailer.report_generation_failed(email, report_type, e.message).deliver_now

      raise e

    ensure
      File.delete(file_path) if file_path && File.exist?(file_path)
    end
  end

  def generate_report_file(format)
    temp_file = Tempfile.new(['all_metrics', ".#{format}"])

    content = render_view(format)

    if format == 'csv'
      File.write(temp_file.path, content, encoding: 'UTF-8')
    else
      File.binwrite(temp_file.path, content)
    end

    temp_file.close
    temp_file.path
  end

  def render_view(format)
    view_path = 'api/v2/accounts/reports/all_conversation_metrics'

    ApplicationController.render(template: view_path, formats: [format.to_sym], locals: { report_data: @report_data },
                                 assigns: { report_data: @report_data })
  end
end
