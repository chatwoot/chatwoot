  class V2::Reports::Templates::MetricBuilder < V2::Reports::Templates::BaseReportBuilder
  def summary
      {
        messages_sent: aggregate_metric('sent'),
        messages_delivered: aggregate_metric('delivered'),
        messages_read: aggregate_metric('read'),
        cost_per_website_button_click: aggregate_metric_cost('cost_per_url_button_click'),
        cost_per_message_delivered: aggregate_metric_cost('cost_per_delivered'),
        amount_spent: aggregate_metric_cost('amount_spent'),
      }
    end

    private

    def aggregate_metric(metric)
      fetch_report.sum { |data| data[metric.to_s] || 0 }
    end

    def aggregate_metric_cost(metric)
      fetch_report.sum do |data|
        data['cost']&.find { |cost| cost['type'] == metric }&.fetch('value', 0) || 0
      end
    end

    def fetch_report
          @report_data ||= begin
          report_data = V2::Reports::Templates::BaseReportBuilder.new(account, params).fetch_report
          report_data = report_data&.flat_map { |report| report['data_points'] }
        end
      end
  end
