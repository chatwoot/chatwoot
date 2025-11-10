class CleanupTempUploadsJob < ApplicationJob
  queue_as :scheduled_jobs

  # Clean up temporary uploaded files older than 24 hours
  def perform
    cleanup_count = 0
    total_size = 0
    temp_dir = Rails.root.join('tmp', 'uploads')

    return unless Dir.exist?(temp_dir)

    cutoff_time = 24.hours.ago

    Dir.glob(temp_dir.join('*')).each do |file_path|
      next unless File.file?(file_path)

      file_mtime = File.mtime(file_path)

      if file_mtime < cutoff_time
        file_size = File.size(file_path)
        File.delete(file_path)
        cleanup_count += 1
        total_size += file_size
        Rails.logger.info("Deleted old temp file: #{File.basename(file_path)} (#{file_size / 1024 / 1024}MB, modified: #{file_mtime})")
      end
    rescue StandardError => e
      Rails.logger.error("Error deleting temp file #{file_path}: #{e.message}")
    end

    if cleanup_count.positive?
      Rails.logger.info("Cleaned up #{cleanup_count} temporary files (#{total_size / 1024 / 1024}MB total)")
    else
      Rails.logger.info('No temporary files to clean up')
    end
  end
end
