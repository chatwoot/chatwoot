class V2::Reports::Templates::BaseReportBuilder
  require 'date'
  pattr_initialize :account, :params



  def fetch_report
    since_date = Time.at(params[:since].to_i).utc.to_datetime
    until_date = Time.at(params[:until].to_i).utc.to_datetime
    since_date = since_date.to_date.prev_day.to_time.to_i
    until_date = until_date.to_date.prev_day.to_time.to_i

    channel = find_channel_by_id(params[:channel_id])

    analytics_data = channel.get_template_analytics(since_date, until_date, [params[:id]])
    if analytics_data == 'Insights are not enabled'
      raise StandardError, analytics_data
    end

     analytics_data
  end

  private

  def find_channel_by_id(channel_id)
    Channel::Whatsapp.find(channel_id)
  end

  def builder_class(metric)
     V2::Reports::Timeseries::CountTemplateReportBuilder
  end


  def log_invalid_metric
    Rails.logger.error "ReportBuilder: Invalid metric - #{params[:metric]}"

    {}
  end
end
