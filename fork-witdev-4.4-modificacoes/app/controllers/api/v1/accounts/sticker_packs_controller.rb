class Api::V1::Accounts::StickerPacksController < Api::V1::Accounts::BaseController
  before_action :set_sticker_pack, only: [:show, :update, :destroy]
  before_action :check_authorization

  def index
    @sticker_packs = current_account.attachments
                                   .where("meta->>'sticker_type' = ?", 'custom')
                                   .select("DISTINCT meta->>'sticker_pack' as pack_name")
                                   .where.not("meta->>'sticker_pack'" => [nil, ''])
                                   .group("meta->>'sticker_pack'")
                                   .order("meta->>'sticker_pack'")

    packs_with_counts = @sticker_packs.map do |pack|
      pack_name = pack.pack_name
      sticker_count = current_account.attachments
                                    .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', pack_name)
                                    .count

      {
        name: pack_name,
        sticker_count: sticker_count,
        created_at: current_account.attachments
                                  .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', pack_name)
                                  .minimum(:created_at)
      }
    end

    render json: { sticker_packs: packs_with_counts }
  end

  def show
    stickers = current_account.attachments
                             .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', params[:id])
                             .includes_blobs
                             .order(:created_at)

    sticker_data = stickers.map do |attachment|
      {
        id: attachment.id,
        url: attachment.download_url,
        filename: attachment.file.filename.to_s,
        size: attachment.file.byte_size,
        created_at: attachment.created_at,
        meta: attachment.meta
      }
    end

    render json: {
      pack_name: params[:id],
      stickers: sticker_data,
      total_count: stickers.count
    }
  end

  def create
    pack_name = sticker_pack_params[:name]
    
    if pack_name.blank?
      render json: { error: 'Pack name is required' }, status: :unprocessable_entity
      return
    end

    # Check if pack already exists
    existing_pack = current_account.attachments
                                  .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', pack_name)
                                  .exists?

    if existing_pack
      render json: { error: 'Sticker pack already exists' }, status: :unprocessable_entity
      return
    end

    render json: { 
      message: 'Sticker pack created successfully',
      pack_name: pack_name
    }, status: :created
  end

  def update
    old_pack_name = params[:id]
    new_pack_name = sticker_pack_params[:name]

    if new_pack_name.blank?
      render json: { error: 'Pack name is required' }, status: :unprocessable_entity
      return
    end

    # Update all stickers in the pack
    stickers = current_account.attachments
                             .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', old_pack_name)

    stickers.find_each do |sticker|
      meta = sticker.meta || {}
      meta['sticker_pack'] = new_pack_name
      sticker.update!(meta: meta)
    end

    render json: { 
      message: 'Sticker pack updated successfully',
      old_name: old_pack_name,
      new_name: new_pack_name
    }
  end

  def destroy
    pack_name = params[:id]
    
    # Delete all stickers in the pack
    stickers = current_account.attachments
                             .where("meta->>'sticker_type' = ? AND meta->>'sticker_pack' = ?", 'custom', pack_name)

    deleted_count = stickers.count
    stickers.destroy_all

    render json: { 
      message: 'Sticker pack deleted successfully',
      deleted_stickers: deleted_count
    }
  end

  def bulk_upload
    pack_name = params[:pack_name]
    files = params[:files] || []

    if pack_name.blank?
      render json: { error: 'Pack name is required' }, status: :unprocessable_entity
      return
    end

    if files.empty?
      render json: { error: 'No files provided' }, status: :unprocessable_entity
      return
    end

    results = []
    errors = []

    files.each_with_index do |file, index|
      begin
        result = StickerService.new(current_account).create_custom_sticker(pack_name, file)
        results << result.merge(index: index)
      rescue StandardError => e
        errors << {
          index: index,
          filename: file.original_filename,
          error: e.message
        }
      end
    end

    render json: {
      message: "Bulk upload completed",
      successful: results.count,
      failed: errors.count,
      results: results,
      errors: errors
    }
  end

  private

  def set_sticker_pack
    # Pack name is passed as ID in the URL
    @pack_name = params[:id]
  end

  def sticker_pack_params
    params.require(:sticker_pack).permit(:name)
  end

  def check_authorization
    authorize(current_account, :admin?)
  end
end