class Shopify::OrderCancellationPollingJob < ApplicationJob
  include Events::Types
  
  # AWAITING_RESPONSE
  # The merchant has taken an action that requires attention from your organization.

  # CLOSED
  # The job has been closed by the merchant.

  # COMPLETED
  # The job has been marked as complete by your organization.

  # DECLINED
  # The job has been declined by the merchant or your organization.

  # EXPIRED
  # The job has expired. A job expires when your organization does not send an initial response to a job within 72 hours.

  # INACTIVE
  # The job has been marked inactive by your organization.

  # NEW
  # The job has been submitted to your organization, but hasn't been opened.

  # OPENED
  # The job has been viewed by your organization.

  # RESPONDED
  # The job has been responded to by your organization.

  queue_as :default
  # JOB_STATUS_QUERY = <<~GRAPHQL
  #   query($id: ID!) {
  #     node(id: $id) {
  #       ... on Job {
  #         id
  #         done
  #         errorCode
  #         errorMessage
  #       }
  #     }
  #   }
  # GRAPHQL
  JOB_STATUS_QUERY = <<~GRAPHQL
    query($id: ID!) {
      job(id: $id) {
        id
        done
      }
    }
  GRAPHQL

  def perform(params)
    job_id, order_id, user_token, shop = params.values_at(:id, :order_id, :user_token, :shop)
    begin
      @order_id = order_id
      @user_token = user_token
      poll_shopify_job(job_id, shop)
    rescue => e
      Rails.logger.error("Error while cancelling shopify order #{order_id} :: #{e}")
    end
  end

  def poll_shopify_job(job_id,shop, timeout: 60, base_interval: 2, max_interval: 16)
    start_time = Time.now
    attempt = 0
    interval = base_interval

    job = nil
    status = 'timeout'
    loop do
      should_break = false
      shop.with_shopify_session do
        response = ShopifyGraphql.execute(
          JOB_STATUS_QUERY,
          id: job_id
        )

        job = response.data.job

        unless job
          raise "Job not found for ID: #{job_id}"
        end

        if job.done
          # if job.errorCode
          #   Rails.logger.info("Job failed: #{job.errorCode} - #{job.errorMessage}")
          #   status = 'failed'
          # else
          Rails.logger.info("Job succeeded!")
          status = 'succeeded'
          should_break = true
          # end
        else
          elapsed = Time.now - start_time
          if elapsed > timeout
            Rails.logger.info("Polling timed out after #{timeout} seconds.")
            status = 'timeout'
            break
          end
          sleep interval
          attempt += 1
          # Exponential backoff: double the interval, but cap at max_interval
          interval = [base_interval * (2 ** attempt), max_interval].min
          Rails.logger.info("Polling again")
        end
      end
      break if should_break
    end

    Rails.configuration.dispatcher.dispatch(
      ORDER_CANCELLATION_UPDATE, Time.zone.now, message: I18n.t('shopify.order_cancellation_done') , status: status, order: Order.find(@order_id), currentUser: @user_token
    )
  end
end
