class Digitaltolk::ProcessParquetJob < ApplicationJob
  queue_as :default
  sidekiq_options timeout: 600

  def perform(parquet_report_id)
    parquet_report = ParquetReport.find_by(id: parquet_report_id)

    if parquet_report.present?
      parquet_report.process!
    end
  rescue StandardError => e
    parquet_report.update_columns(status: "failed", error_message: e.message)
  end
end