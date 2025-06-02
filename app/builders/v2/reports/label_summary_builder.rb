class V2::Reports::LabelSummaryBuilder < V2::Reports::BaseSummaryBuilder
  pattr_initialize [:account!, :params!]

  def build
    # Leverage the optimized V2::LabelReportBuilder for bulk operations
    V2::LabelReportBuilder.new(account, params).build
  end
end
