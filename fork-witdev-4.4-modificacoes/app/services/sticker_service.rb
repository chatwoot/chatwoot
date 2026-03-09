class StickerService
  CUSTOM_STICKERS_CACHE_TTL = 1.hour
  STICKER_PACKS_CACHE_TTL = 30.minutes
  CACHE_PREFIX = 'custom_stickers'
  
  # Custom error classes for better error handling
  class StickerError < StandardError; end
  class InvalidAccountError < StickerError; end
  class StickerNotFoundError < StickerError; end
  class ValidationError < StickerError; end
  class StorageError < StickerError; end
  
  def initialize(account)
    raise InvalidAccountError, 'Account is required' unless account
    @account = account
  end

  # Leverages the existing Attachment model for custom stickers with caching
  def custom_stickers(pack_name = nil)
    cache_key = generate_stickers_cache_key(pack_name)
    
    # Check cache using Redis::Alfred (Chatwoot pattern)
    cached_stickers = Redis::Alfred.get(cache_key)
    cache_hit = cached_stickers.present?
    increment_cache_metric(cache_hit ? 'hit' : 'miss')

    if cache_hit
      # Parse JSON from cache
      JSON.parse(cached_stickers)
    else
      Rails.logger.info "StickerService: Cache miss for stickers #{cache_key}"
      stickers = fetch_custom_stickers_from_db(pack_name)
      
      # Save to cache using Redis::Alfred
      Redis::Alfred.setex(cache_key, stickers.to_json, CUSTOM_STICKERS_CACHE_TTL)
      
      stickers
    end
  rescue StandardError => e
    Rails.logger.error "StickerService custom_stickers error: #{e.message}"
    increment_cache_metric('error')
    []
  end

  def custom_sticker_packs
    cache_key = generate_packs_cache_key
    
    # Check cache using Redis::Alfred (Chatwoot pattern)
    cached_packs = Redis::Alfred.get(cache_key)
    cache_hit = cached_packs.present?
    increment_cache_metric(cache_hit ? 'packs_hit' : 'packs_miss')

    if cache_hit
      # Parse JSON from cache
      JSON.parse(cached_packs)
    else
      Rails.logger.info "StickerService: Cache miss for packs #{cache_key}"
      packs = fetch_sticker_packs_from_db
      
      # Save to cache using Redis::Alfred
      Redis::Alfred.setex(cache_key, packs.to_json, STICKER_PACKS_CACHE_TTL)
      
      packs
    end
  rescue StandardError => e
    Rails.logger.error "StickerService custom_sticker_packs error: #{e.message}"
    increment_cache_metric('packs_error')
    []
  end

  # Generate sticker-specific URL that doesn't interfere with native media handling
  def self.sticker_url_for_whatsapp(attachment)
    return '' unless attachment&.file&.attached?
    
    # Use the sticker-specific method that generates proper external URLs
    attachment.sticker_download_url
  end

  def create_custom_sticker(pack_name, file, tags = [])
    validate_sticker_creation_params!(pack_name, file)
    
    uploader = StickerUploader.new(
      file: file,
      pack_name: pack_name,
      tags: tags
    )

    unless uploader.process_and_validate
      return build_validation_error_response(uploader.errors)
    end

    begin
      attachment = create_attachment_with_processed_file(uploader)
      
      # Invalidate relevant caches
      invalidate_stickers_cache(pack_name)
      invalidate_packs_cache
      
      {
        success: true,
        sticker: {
          id: attachment.id,
          url: StickerService.sticker_url_for_whatsapp(attachment),
          alt: pack_name,
          provider: 'custom',
          meta: attachment.meta
        }
      }
    rescue ValidationError => e
      Rails.logger.error "StickerService validation error: #{e.message}"
      
      StickerErrorLoggerService.log_error(
        error_code: 'VALIDATION_ERROR',
        error_message: e.message,
        context: { pack_name: pack_name, service: 'StickerService', action: 'create_custom_sticker' },
        account: @account
      )
      
      build_error_response('VALIDATION_ERROR', e.message)
    rescue StorageError => e
      Rails.logger.error "StickerService storage error: #{e.message}"
      
      StickerErrorLoggerService.log_error(
        error_code: 'STORAGE_ERROR',
        error_message: e.message,
        context: { pack_name: pack_name, service: 'StickerService', action: 'create_custom_sticker' },
        account: @account
      )
      
      build_error_response('STORAGE_ERROR', 'Failed to save sticker. Please try again.')
    rescue StandardError => e
      Rails.logger.error "StickerService unexpected error: #{e.message}\n#{e.backtrace.join("\n")}"
      
      StickerErrorLoggerService.log_error(
        error_code: 'UNKNOWN_ERROR',
        error_message: e.message,
        context: { 
          pack_name: pack_name, 
          service: 'StickerService', 
          action: 'create_custom_sticker',
          backtrace: e.backtrace&.first(5)
        },
        account: @account
      )
      
      build_error_response('UNKNOWN_ERROR', 'An unexpected error occurred. Please try again.')
    ensure
      # Clean up temporary file safely
      if uploader.processed_file
        begin
          uploader.processed_file.close if uploader.processed_file.respond_to?(:close)
          uploader.processed_file.unlink if uploader.processed_file.respond_to?(:unlink)
        rescue StandardError => e
          Rails.logger.debug "StickerService: Could not cleanup temp file: #{e.message}"
        end
      end
    end
  end

  def delete_custom_sticker(sticker_id)
    validate_sticker_id!(sticker_id)
    
    attachment = find_custom_sticker(sticker_id)
    raise StickerNotFoundError, 'Sticker not found' unless attachment

    begin
      pack_name = attachment.meta&.dig('sticker_pack')
      attachment.destroy!
      
      # Invalidate relevant caches
      invalidate_stickers_cache(pack_name)
      invalidate_packs_cache
      
      { success: true }
    rescue StickerNotFoundError => e
      Rails.logger.error "StickerService sticker not found: #{e.message}"
      
      StickerErrorLoggerService.log_error(
        error_code: 'STICKER_NOT_FOUND',
        error_message: e.message,
        context: { sticker_id: sticker_id, service: 'StickerService', action: 'delete_custom_sticker' },
        account: @account
      )
      
      build_error_response('STICKER_NOT_FOUND', 'Sticker not found')
    rescue StandardError => e
      Rails.logger.error "StickerService delete error: #{e.message}"
      
      StickerErrorLoggerService.log_error(
        error_code: 'DELETE_ERROR',
        error_message: e.message,
        context: { 
          sticker_id: sticker_id, 
          service: 'StickerService', 
          action: 'delete_custom_sticker',
          backtrace: e.backtrace&.first(5)
        },
        account: @account
      )
      
      build_error_response('DELETE_ERROR', 'Failed to delete sticker. Please try again.')
    end
  end

  def update_sticker_pack(sticker_id, new_pack_name)
    attachment = Attachment.find_by(
      id: sticker_id,
      account: @account,
      file_type: :image
    )

    return { success: false, error: 'Sticker not found' } unless attachment
    return { success: false, error: 'Not a custom sticker' } unless attachment.meta&.dig('sticker_type') == 'custom'

    begin
      old_pack_name = attachment.meta&.dig('sticker_pack')
      meta = attachment.meta || {}
      meta['sticker_pack'] = new_pack_name
      attachment.update!(meta: meta)
      
      # Invalidate relevant caches
      invalidate_stickers_cache(old_pack_name)
      invalidate_stickers_cache(new_pack_name)
      invalidate_packs_cache
      
      { success: true }
    rescue StandardError => e
      Rails.logger.error "Failed to update sticker pack: #{e.message}"
      { success: false, error: 'Failed to update sticker pack' }
    end
  end

  def invalidate_all_caches
    # Invalidate all sticker-related caches for this account using Redis::Alfred
    # Note: Redis::Alfred doesn't have delete_matched, so we invalidate specific known caches
    
    # Invalidate stickers cache (all packs)
    all_stickers_key = generate_stickers_cache_key(nil)
    Redis::Alfred.delete(all_stickers_key)
    
    # Invalidate packs cache
    packs_key = generate_packs_cache_key
    Redis::Alfred.delete(packs_key)
    
    # Note: For specific pack caches, we'd need to track pack names or iterate
    # This is a limitation of not having delete_matched, but follows Chatwoot patterns
    
    Rails.logger.info "StickerService: Invalidated all caches for account #{@account.id}"
  end

  private

  attr_reader :account

  def validate_sticker_creation_params!(pack_name, file)
    raise ValidationError, 'Pack name is required' if pack_name.blank?
    raise ValidationError, 'File is required' unless file
    raise ValidationError, 'Pack name too long (max 50 characters)' if pack_name.length > 50
    raise ValidationError, 'Invalid pack name format' unless pack_name.match?(/\A[a-zA-Z0-9\s\-_]+\z/)
    
    # Validate file is actually a file-like object
    unless file.respond_to?(:read) || file.respond_to?(:path)
      raise ValidationError, 'Invalid file format'
    end
  end

  def validate_sticker_id!(sticker_id)
    raise ValidationError, 'Sticker ID is required' if sticker_id.blank?
    raise ValidationError, 'Invalid sticker ID format' unless sticker_id.to_s.match?(/\A\d+\z/)
  end

  def find_custom_sticker(sticker_id)
    attachment = Attachment.find_by(
      id: sticker_id,
      account: @account,
      file_type: :image
    )

    return nil unless attachment
    return nil unless attachment.meta&.dig('sticker_type') == 'custom'
    
    attachment
  end

  def build_error_response(error_code, message)
    {
      success: false,
      error: message,
      error_code: error_code,
      user_message: get_user_friendly_message(error_code)
    }
  end

  def build_validation_error_response(errors)
    {
      success: false,
      errors: errors.is_a?(Array) ? errors : [errors.to_s],
      error_code: 'VALIDATION_ERROR',
      user_message: 'Please check your sticker file and try again.'
    }
  end

  def get_user_friendly_message(error_code)
    case error_code
    when 'VALIDATION_ERROR'
      'Invalid sticker data. Please check your input and try again.'
    when 'STORAGE_ERROR'
      'Failed to save sticker. Please check your internet connection and try again.'
    when 'STICKER_NOT_FOUND'
      'Sticker not found. It may have been deleted already.'
    when 'DELETE_ERROR'
      'Failed to delete sticker. Please try again.'
    when 'UPDATE_ERROR'
      'Failed to update sticker. Please try again.'
    else
      'An error occurred. Please try again.'
    end
  end

  def fetch_custom_stickers_from_db(pack_name = nil)
    # Optimized query with proper indexing considerations
    query = base_stickers_query
    query = query.where("meta->>'sticker_pack' = ?", pack_name) if pack_name.present?
    
    # Use includes to avoid N+1 queries - include blob for URL generation
    query.includes(file_attachment: :blob).map do |attachment|
      {
        id: attachment.id,
        url: StickerService.sticker_url_for_whatsapp(attachment),
        alt: attachment.meta&.dig('sticker_pack') || 'Custom Sticker',
        provider: 'custom',
        meta: attachment.meta
      }
    end
  end

  def fetch_sticker_packs_from_db
    # Optimized query to get distinct pack names
    base_stickers_query
      .distinct
      .pluck(Arel.sql("meta->>'sticker_pack'"))
      .compact
      .sort
      .map { |pack_name| { id: pack_name, name: pack_name } }
  end

  def base_stickers_query
    # Base query with proper indexing hints
    Attachment.where(
      account: @account,
      file_type: :image
    ).where("meta->>'sticker_type' = ?", 'custom')
     .order(:created_at)
  end

  def generate_stickers_cache_key(pack_name = nil)
    pack_name_key = pack_name || 'all'
    format(Redis::RedisKeys::STICKER_CACHE, account_id: @account.id, pack_name: pack_name_key)
  end

  def generate_packs_cache_key
    format(Redis::RedisKeys::STICKER_PACKS_CACHE, account_id: @account.id)
  end

  def invalidate_stickers_cache(pack_name = nil)
    if pack_name
      cache_key = generate_stickers_cache_key(pack_name)
      Redis::Alfred.delete(cache_key)
    end
    
    # Also invalidate the "all stickers" cache
    all_cache_key = generate_stickers_cache_key(nil)
    Redis::Alfred.delete(all_cache_key)
    
    Rails.logger.info "StickerService: Invalidated stickers cache for pack: #{pack_name || 'all'}"
  end

  def invalidate_packs_cache
    cache_key = generate_packs_cache_key
    Redis::Alfred.delete(cache_key)
    Rails.logger.info "StickerService: Invalidated packs cache"
  end

  def increment_cache_metric(type)
    # Use Redis::Alfred for metrics (Chatwoot pattern)
    metric_key = format(Redis::RedisKeys::STICKER_METRICS, metric_type: "sticker_service_cache_#{type}")
    
    # Redis::Alfred doesn't have increment with expiry, so we use a simple approach
    current_value = Redis::Alfred.get(metric_key).to_i
    Redis::Alfred.setex(metric_key, current_value + 1, 1.hour)
  rescue StandardError => e
    Rails.logger.warn "Failed to increment sticker cache metric: #{e.message}"
  end

  def create_attachment_with_processed_file(uploader)
    # For now, we'll create a simple attachment without a message
    # This is a temporary approach - in production you might want to 
    # create a dedicated sticker storage system
    
    # Create a dummy message for the attachment requirement
    # We'll use the first available conversation or create a system one
    message = find_or_create_system_message

    attachment = Attachment.new(
      account: @account,
      message: message,
      file_type: :image,
      meta: {
        sticker_type: 'custom',
        sticker_pack: uploader.pack_name,
        tags: uploader.tags,
        created_at: Time.current.iso8601,
        dimensions: "#{StickerUploader::STICKER_DIMENSIONS}x#{StickerUploader::STICKER_DIMENSIONS}",
        format: 'webp'
      }
    )

    # CORREÇÃO: Garantir que o arquivo seja salvo sem processamento adicional do ActiveStorage
    # Primeiro, vamos garantir que o tempfile está no início
    uploader.processed_file.rewind if uploader.processed_file.respond_to?(:rewind)
    
    # Vamos tentar anexar diretamente o arquivo sem usar create_and_upload!
    # que pode estar fazendo reprocessamento
    attachment.file.attach(
      io: uploader.processed_file,
      filename: uploader.processed_filename,
      content_type: 'image/webp',
      metadata: {
        # Incluir metadados que indicam que o arquivo já foi processado
        'analyzed' => true,
        'identified' => true,
        'processed_by_sticker_optimizer' => true
      }
    )

    attachment.save!
    attachment
  end

  def find_or_create_system_message
    # Try to find an existing system message for stickers
    existing_attachment = Attachment.joins(:message)
                                   .where(account: @account)
                                   .where("meta->>'sticker_type' = ?", 'custom')
                                   .first

    return existing_attachment.message if existing_attachment

    # If no existing system message, create a simple one
    # Use the first available conversation or create a basic one
    conversation = @account.conversations.first
    
    unless conversation
      # Create a minimal conversation for system use
      # This is a fallback - in a real system you'd have better setup
      inbox = @account.inboxes.first
      if inbox
        contact = @account.contacts.first || @account.contacts.create!(
          name: 'System',
          email: 'system@chatwoot.local'
        )
        
        contact_inbox = inbox.contact_inboxes.find_or_create_by!(
          contact: contact,
          source_id: 'system'
        )
        
        conversation = @account.conversations.create!(
          inbox: inbox,
          contact: contact,
          contact_inbox: contact_inbox,
          additional_attributes: { system_conversation: true }
        )
      else
        raise StandardError, 'No inbox available for sticker storage'
      end
    end

    # Create a system message for sticker storage
    conversation.messages.create!(
      content: 'System message for custom sticker storage',
      message_type: :activity,
      account_id: @account.id,
      inbox_id: conversation.inbox_id,
      additional_attributes: { system_message: true, sticker_storage: true }
    )
  end
end