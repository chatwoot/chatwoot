class V2::Reports::Templates::ReportBuilder < V2::Reports::Templates::BaseReportBuilder
  def report(metric)
    metric_name = metric_handler(metric)
    build_report(metric_name)
  end

  private

  def build_report(metric_name)
    report_fetched = fetch_report.map do |data|
      {
        value: data[metric_name] || 0,
        timestamp: data['end']
      }
    end
    report_fetched
  end

  def fetch_report 
    report_data = V2::Reports::Templates::BaseReportBuilder.new(account, params).fetch_report
    report_data&.flat_map { |report| report['data_points'] }
  end

  def metric_handler(metric)
    template_metrics = {
      'messages_delivered' => 'delivered',
      'messages_read' => 'read',
      'messages_sent' => 'sent'
    }

    template_metrics[metric] || 'unknown_metric'
  end
end
