class Api::V1::Accounts::Admin::StickersController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_sticker, only: [:show, :update, :destroy]

  def index
    @stickers = current_account.attachments
                              .where("meta->>'sticker_type' = ?", 'custom')
                              .includes_blobs
                              .order(:created_at)

    # Filter by pack if specified
    if params[:pack_name].present?
      @stickers = @stickers.where("meta->>'sticker_pack' = ?", params[:pack_name])
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    offset = (page - 1) * per_page

    total_count = @stickers.count
    @stickers = @stickers.limit(per_page).offset(offset)

    sticker_data = @stickers.map do |attachment|
      {
        id: attachment.id,
        url: attachment.download_url,
        filename: attachment.file.filename.to_s,
        size: attachment.file.byte_size,
        pack_name: attachment.meta&.dig('sticker_pack'),
        tags: attachment.meta&.dig('tags') || [],
        created_at: attachment.created_at,
        updated_at: attachment.updated_at
      }
    end

    render json: {
      stickers: sticker_data,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def show
    render json: {
      id: @sticker.id,
      url: @sticker.download_url,
      filename: @sticker.file.filename.to_s,
      size: @sticker.file.byte_size,
      content_type: @sticker.file.content_type,
      pack_name: @sticker.meta&.dig('sticker_pack'),
      tags: @sticker.meta&.dig('tags') || [],
      created_at: @sticker.created_at,
      updated_at: @sticker.updated_at,
      meta: @sticker.meta
    }
  end

  def create
    pack_name = sticker_params[:pack_name]
    file = sticker_params[:file]
    tags = sticker_params[:tags] || []

    if pack_name.blank?
      render json: { error: 'Pack name is required' }, status: :unprocessable_entity
      return
    end

    if file.blank?
      render json: { error: 'File is required' }, status: :unprocessable_entity
      return
    end

    begin
      result = StickerService.new(current_account).create_custom_sticker(pack_name, file, tags)
      render json: result, status: :created
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def update
    pack_name = sticker_params[:pack_name]
    tags = sticker_params[:tags]

    meta = @sticker.meta || {}
    meta['sticker_pack'] = pack_name if pack_name.present?
    meta['tags'] = tags if tags.present?

    if @sticker.update(meta: meta)
      render json: {
        id: @sticker.id,
        url: @sticker.download_url,
        filename: @sticker.file.filename.to_s,
        pack_name: meta['sticker_pack'],
        tags: meta['tags'] || [],
        updated_at: @sticker.updated_at
      }
    else
      render json: { errors: @sticker.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @sticker.destroy!
    render json: { message: 'Sticker deleted successfully' }
  end

  def validate_file
    file = params[:file]
    
    if file.blank?
      render json: { error: 'No file provided' }, status: :unprocessable_entity
      return
    end

    begin
      # Use StickerUploader to validate the file
      uploader = StickerUploader.new
      uploader.store!(file)
      
      # Get file info
      file_info = {
        filename: file.original_filename,
        size: file.size,
        content_type: file.content_type,
        valid: true,
        preview_url: uploader.url
      }

      render json: file_info
    rescue StandardError => e
      render json: {
        filename: file.original_filename,
        size: file.size,
        content_type: file.content_type,
        valid: false,
        error: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_sticker
    @sticker = current_account.attachments
                             .where("meta->>'sticker_type' = ?", 'custom')
                             .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Sticker not found' }, status: :not_found
  end

  def sticker_params
    params.permit(:pack_name, :file, tags: [])
  end

  def check_authorization
    authorize(current_account, :admin?)
  end
end