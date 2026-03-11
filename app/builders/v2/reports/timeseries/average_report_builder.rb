class V2::Reports::Timeseries::AverageReportBuilder < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def timeseries
    data_source.timeseries
  end

  def aggregate_value
    data_source.aggregate
  end
end
