class Api::V1::Accounts::Inboxes::AppleListPickerImagesController < Api::V1::Accounts::BaseController
  before_action :fetch_inbox
  # No authorization check needed - if user can access the inbox via fetch_inbox, they can manage images

  def index
    @images = @inbox.apple_list_picker_images.for_inbox(@inbox.id)
    Rails.logger.info "[AppleListPickerImages API] Returning #{@images.count} images for inbox #{@inbox.id}"
    render json: serialize_images(@images)
  rescue StandardError => e
    Rails.logger.error "[AppleListPickerImages API] Error loading images: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  def create
    @image = @inbox.apple_list_picker_images.new(image_params)
    @image.account_id = Current.account.id

    if params[:image_file].present?
      @image.image.attach(params[:image_file])
    elsif params[:image_data].present?
      # Handle base64 data
      decoded_data = Base64.strict_decode64(params[:image_data])
      filename = params[:filename] || "#{params[:identifier]}.jpg"
      content_type = params[:content_type] || 'image/jpeg'

      @image.image.attach(
        io: StringIO.new(decoded_data),
        filename: filename,
        content_type: content_type
      )
    end

    if @image.save
      render json: serialize_image(@image), status: :created
    else
      render json: { errors: @image.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @image = @inbox.apple_list_picker_images.find(params[:id])
    @image.destroy
    head :no_content
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
  end

  def image_params
    params.permit(:identifier, :description, :original_name)
  end

  def serialize_images(images)
    images.map { |img| serialize_image(img) }
  end

  def serialize_image(image)
    {
      id: image.id,
      identifier: image.identifier,
      description: image.description,
      original_name: image.original_name,
      image_url: image.image_url,
      image_data_base64: nil, # Don't send base64 by default, only on demand
      created_at: image.created_at,
      updated_at: image.updated_at
    }
  end
end
