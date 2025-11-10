class Api::V1::Accounts::BulkProcessingRequestsController < Api::V1::Accounts::BaseController
  before_action :bulk_processing_request, except: [:index, :create]
  before_action :check_authorization

  def index
    page = params[:page] || 1
    per_page = params[:per_page] || 50
    entity_type = params[:entity_type]

    base_query = Current.account.bulk_processing_requests.includes(:user)

    @bulk_processing_requests = if entity_type.present?
                                  base_query.where(entity_type: entity_type)
                                            .order(created_at: :desc)
                                            .page(page)
                                            .per(per_page)
                                else
                                  base_query.order(created_at: :desc)
                                            .page(page)
                                            .per(per_page)
                                end

    @total_count = @bulk_processing_requests.total_count
    @total_pages = (@total_count.to_f / per_page.to_i).ceil
    @current_page = page.to_i
  end

  def show; end

  def download_errors
    require 'csv'

    csv_data = CSV.generate(headers: true) do |csv|
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

    @bulk_processing_request.update!(
      status: 'CANCELLED',
      error_message: 'Cancelled by user',
      dismissed_at: Time.current
    )

    head :ok
  end

  def dismiss
    @bulk_processing_request.update!(dismissed_at: Time.current)
    head :ok
  end

  private

  def bulk_processing_request
    @bulk_processing_request ||= Current.account.bulk_processing_requests.find(params[:id])
  end
end
