class Digitaltolk::ProcessParquetJob < ApplicationJob
  queue_as :default

  def perform(parquet_report_id)
    parquet_report = ParquetReport.find_by(id: parquet_report_id)

    if parquet_report.present?
      parquet_report.process!
    end
  end
end