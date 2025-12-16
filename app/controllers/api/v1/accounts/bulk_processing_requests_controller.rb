class Api::V1::Accounts::BulkProcessingRequestsController < Api::V1::Accounts::BaseController
  before_action :bulk_processing_request, except: [:index, :create]
  before_action :check_authorization

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50
    entity_type = params[:entity_type]
    operation_type = params[:operation_type]
    include_dismissed = ActiveModel::Type::Boolean.new.cast(params[:include_dismissed])

    base_query = Current.account.bulk_processing_requests.includes(:user)

    # By default, exclude dismissed requests (for polling use case)
    # Pass include_dismissed=true to get all records (for upload history page)
    base_query = base_query.where(dismissed_at: nil) unless include_dismissed

    # Filter by entity_type if provided
    base_query = base_query.where(entity_type: entity_type) if entity_type.present?

    # Filter by operation_type if provided (UPLOAD, EXPORT, DELETE)
    base_query = base_query.where(operation_type: operation_type) if operation_type.present?

    @bulk_processing_requests = base_query.order(created_at: :desc)
                                          .page(page)
                                          .per(per_page)

    @total_count = @bulk_processing_requests.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
  end

  def show; end

  def download_errors
    # Use CSVSafe to prevent CSV injection (formula injection in Excel)
    csv_data = CSVSafe.generate do |csv|
      csv << ['Row', 'Product ID', 'Product Name', 'Error']

      (@bulk_processing_request.error_details || []).each do |error|
        csv << [
          error['row'],
          error['product_id'] || 'N/A',
          error['product_name'] || 'N/A',
          error['error']
        ]
      end
    end

    send_data csv_data,
              filename: "errors_#{@bulk_processing_request.file_name.gsub('.xlsx', '')}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def cancel
    unless ['PENDING', 'PROCESSING', 'FAILED'].include?(@bulk_processing_request.status.upcase)
      return render json: { error: 'Cannot cancel completed request' }, status: :unprocessable_entity
    end

    # Try to delete the job from the Sidekiq queue
    if @bulk_processing_request.job_id.present?
      begin
        require 'sidekiq/api'

        # Try to find and delete from scheduled/retry queues
        deleted = false

        # Check scheduled jobs
        Sidekiq::ScheduledSet.new.each do |job|
          if job.jid == @bulk_processing_request.job_id
            job.delete
            deleted = true
            Rails.logger.info("Deleted scheduled job #{@bulk_processing_request.job_id}")
            break
          end
        end

        # Check retry queue
        unless deleted
          Sidekiq::RetrySet.new.each do |job|
            if job.jid == @bulk_processing_request.job_id
              job.delete
              deleted = true
              Rails.logger.info("Deleted retry job #{@bulk_processing_request.job_id}")
              break
            end
          end
        end

        # Check regular queues
        unless deleted
          Sidekiq::Queue.all.each do |queue|
            queue.each do |job|
              if job.jid == @bulk_processing_request.job_id
                job.delete
                deleted = true
                Rails.logger.info("Deleted queued job #{@bulk_processing_request.job_id} from queue #{queue.name}")
                break
              end
            end
            break if deleted
          end
        end

        Rails.logger.info("Job #{@bulk_processing_request.job_id} deletion: #{deleted}") unless deleted
      rescue => e
        Rails.logger.error("Error deleting Sidekiq job #{@bulk_processing_request.job_id}: #{e.message}")
      end
    end

    # If this is an export operation, purge any attached files created during processing
    if @bulk_processing_request.operation_export?
      purge_export_files
    end

    @bulk_processing_request.update!(
      status: 'CANCELLED',
      error_message: 'Cancelled by user',
      dismissed_at: Time.current
    )

    head :ok
  end

  def dismiss
    # If this is an export operation, purge attached files
    if @bulk_processing_request.operation_export?
      purge_export_files
    end

    @bulk_processing_request.update!(dismissed_at: Time.current)
    head :ok
  end

  private

  def bulk_processing_request
    @bulk_processing_request ||= Current.account.bulk_processing_requests.find(params[:id])
  end

  def purge_export_files
    # Purge multiple export files (new format)
    if @bulk_processing_request.export_files.attached?
      count = @bulk_processing_request.export_files.count
      @bulk_processing_request.export_files.purge
      Rails.logger.info "#{count} export files purged for bulk_request_id=#{@bulk_processing_request.id}"
    end

    # Purge legacy single export file
    if @bulk_processing_request.export_file.attached?
      @bulk_processing_request.export_file.purge
      Rails.logger.info "Legacy export file purged for bulk_request_id=#{@bulk_processing_request.id}"
    end
  end
end
