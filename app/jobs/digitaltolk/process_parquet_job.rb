class Digitaltolk::ProcessParquetJob < ApplicationJob
  queue_as :low
  sidekiq_options retry: 3

  def perform(report)
    begin
      if report.present?
        report.process!
      else
        Rails.logger.error "Parquet Report not found #{report}"
      end
    rescue StandardError => e
      report.failed!(e.message) if report.present?
      Rails.logger.error "Error processing Parquet Report #{report&.id}: #{e.message}"
    end
  end
end