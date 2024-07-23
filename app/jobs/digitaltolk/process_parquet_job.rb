class Digitaltolk::ProcessParquetJob < ApplicationJob
  queue_as :default
  sidekiq_options timeout: 600

  def perform(parquet_report_id)
    parquet_report = ParquetReport.find_by(id: parquet_report_id)

    if parquet_report.present?
      parquet_report.process!
    else
      Rails.logger.error "Parquet Report not found #{parquet_report_id}"
    end
  rescue StandardError => e
    parquet_report.failed!(e.message) if parquet_report.present?
    Rails.logger.error "Error processing Parquet Report #{parquet_report_id}: #{e.message}"
  end
end