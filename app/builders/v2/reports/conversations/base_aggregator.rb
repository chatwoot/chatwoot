class V2::Reports::Conversations::BaseAggregator < V2::Reports::Timeseries::BaseTimeseriesBuilder
  def metrics
    return {} if range.blank?

    compute_metrics
  end

  private

  def compute_metrics
    raise NotImplementedError, 'Subclasses must implement #compute_metrics'
  end
end
