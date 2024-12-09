class Onehash::Cal::CalBookingController < Onehash::IntegrationController
  before_action :validate_create_params, only: [:create]
  before_action :validate_update_params, only: [:update]
  before_action :validate_delete_params, only: [:destroy]

  def create
    account_user_ids = params[:account_user_ids]
    booking = booking_create_params
    CreateCalBookingJob.perform_later(account_user_ids, booking)
    render json: { message: 'Booking creation process started' }, status: :accepted
  rescue StandardError => e
    logger.error "Error enqueuing create booking job: #{e.message}"
    render json: { error: 'Failed to enqueue booking creation job' }, status: :unprocessable_entity
  end

  def update
    booking = booking_update_params
    UpdateCalBookingJob.perform_later(booking)
    render json: { message: 'Booking update process started' }, status: :accepted
  rescue StandardError => e
    logger.error "Error enqueuing update booking job: #{e.message}"
    render json: { error: 'Failed to enqueue booking update job' }, status: :unprocessable_entity
  end

  def destroy
    booking_uids = params[:bookingUids].split(',')

    render json: { error: 'No bookingUids provided' }, status: :unprocessable_entity and return if booking_uids.empty?

    DestroyCalBookingJob.perform_later(booking_uids)

    render json: { message: 'Booking deletion process started' }, status: :accepted
  rescue StandardError => e
    logger.error "Error enqueuing delete booking job: #{e.message}"
    render json: { error: 'Failed to enqueue booking deletion job' }, status: :unprocessable_entity
  end

  private

  def booking_create_params
    params.require(:booking).permit(:hostName, :bookingLocation, :bookingEventType,
                                    :bookingStartTime, :bookingEndTime, :bookerEmail, :bookingUid)
  end

  def booking_update_params
    params.require(:booking).permit(:hostName, :bookingLocation, :bookingEventType,
                                    :bookingStartTime, :bookingEndTime, :bookingUid, :originalBookingUid)
  end

  def validate_create_params
    unless params[:account_user_ids].is_a?(Array) && params[:account_user_ids].present?
      render json: { error: 'account_user_ids must be a non-empty array' }, status: :unprocessable_entity and return
    end

    booking = params[:booking]
    required_booking_fields = [
      :hostName, :bookingLocation, :bookingEventType,
      :bookingStartTime, :bookingEndTime, :bookerEmail,  :bookingUid
    ]

    missing_fields = required_booking_fields.select { |field| booking[field].blank? }

    return if missing_fields.empty?

    render json: { error: "Missing required booking fields: #{missing_fields.join(', ')}" }, status: :unprocessable_entity and return
  end

  def validate_update_params
    booking = params[:booking]
    unless booking && booking[:bookingUid].present?
      render json: { error: 'Missing required bookingUid in booking data' }, status: :unprocessable_entity and return
    end

    required_booking_fields = [
      :hostName, :bookingLocation, :bookingEventType,
      :bookingStartTime, :bookingEndTime, :bookingUid
    ]

    missing_fields = required_booking_fields.select { |field| booking[field].blank? }

    return if missing_fields.empty?

    render json: { error: "Missing required fields: #{missing_fields.join(', ')}" }, status: :unprocessable_entity and return
  end

  def validate_delete_params
    params[:bookingUids] = params[:bookingUids].split(',')
    return if params[:bookingUids].present? && params[:bookingUids].is_a?(Array) && params[:bookingUids].all?(String)

    render json: { error: 'Missing or invalid bookingUids query parameter' }, status: :unprocessable_entity and return
  end
end
