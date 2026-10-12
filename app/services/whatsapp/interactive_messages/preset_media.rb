class Whatsapp::InteractiveMessages::PresetMedia
  include FileTypeHelper

  def self.sync!(preset, attachments: nil)
    new(preset, attachments).sync!
  end

  def initialize(preset, attachments)
    @preset = preset
    @attachments = attachments
  end

  def sync!
    blobs = @attachments.nil? ? existing_blobs : supplied_blobs
    validate_media!(blobs)
    replace_media!(blobs) unless @attachments.nil?
  end

  private

  def existing_blobs
    @preset.media.includes(file_attachment: :blob).map { |medium| medium.file.blob }
  end

  def supplied_blobs
    validation_error!('attachments must be an ordered array') unless @attachments.is_a?(Array)

    @attachments.map do |signed_id|
      validation_error!('attachments must contain valid signed blob IDs') unless signed_id.is_a?(String)

      ActiveStorage::Blob.find_signed(signed_id) || validation_error!('attachments contain an invalid signed blob ID')
    end
  end

  def validate_media!(blobs)
    expected_types = expected_media_types
    validation_error!("attachments must contain #{expected_types.length} ordered media references") unless blobs.length == expected_types.length

    blobs.zip(expected_types).each do |blob, expected_type|
      validation_error!('attachments contain media that belongs to another account') unless account_owned?(blob)
      validation_error!("attachments must match the ordered #{expected_type} media slots") unless matching_media?(blob, expected_type)
    end
  end

  def expected_media_types
    definition = @preset.definition
    return Array.new(definition.dig('action', 'cards').length, 'image') if definition['type'] == 'carousel'

    header_type = definition.dig('header', 'type')
    %w[image video document].include?(header_type) ? [header_type] : []
  end

  def matching_media?(blob, expected_type)
    content_type = blob.content_type.to_s
    return file_type(content_type).to_s == expected_type && content_type.start_with?("#{expected_type}/") unless expected_type == 'document'

    file_type(content_type) == :file && !content_type.start_with?('image/', 'video/', 'audio/')
  end

  def account_owned?(blob)
    associations = blob.attachments.to_a
    return true if associations.empty?

    associations.all? do |association|
      record = association.record
      (record.is_a?(Attachment) || record.is_a?(WhatsappInteractivePresetMedia)) && record.account_id == @preset.account_id
    end
  end

  def replace_media!(blobs)
    old_media = @preset.media.to_a
    temporary_position = [old_media.map(&:position).max.to_i, blobs.length].max + 1
    new_media = blobs.map.with_index do |blob, index|
      medium = @preset.media.build(position: temporary_position + index)
      medium.file.attach(blob)
      medium.save!
      medium
    end

    old_media.each(&:destroy!)
    new_media.each_with_index { |medium, position| medium.update!(position: position) }
    @preset.media.reset
  end

  def validation_error!(message)
    raise Whatsapp::InteractiveMessages::ValidationError, message
  end
end
