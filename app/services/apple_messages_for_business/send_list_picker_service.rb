class AppleMessagesForBusiness::SendListPickerService < AppleMessagesForBusiness::SendMessageService
  def perform
    # Save images before sending
    save_images_to_storage

    # Call parent perform
    super
  end

  private

  # Override parent to use transformed images
  def build_interactive_data
    base_data = super

    # Replace the raw images with properly formatted ones (base64 data)
    if content_attributes['images'].present?
      base_data[:data][:images] = build_images_array
      Rails.logger.info "[AMB ListPicker] Added #{base_data[:data][:images].length} formatted images to payload"
      # Debug: log image identifiers being sent
      Rails.logger.info "[AMB ListPicker] Image identifiers: #{base_data[:data][:images].map { |img| img[:identifier] }.join(', ')}"
      # Debug: log first 100 chars of first image data
      if base_data[:data][:images].first
        first_img = base_data[:data][:images].first
        Rails.logger.info "[AMB ListPicker] First image data present: #{first_img[:data].present?}, length: #{first_img[:data]&.length}"
      end
    end

    base_data
  end

  def save_images_to_storage
    images = content_attributes['images'] || []
    Rails.logger.info "[AMB ListPicker] save_images_to_storage called with #{images.length} images"
    return if images.empty?

    # Performance Optimization: Batch fetch all existing images to avoid N+1 queries
    # This replaces multiple find_by_identifier calls with a single WHERE IN query
    image_identifiers = images.map { |img| img['identifier'] }.compact.uniq
    existing_images = AppleListPickerImage
                      .where(inbox_id: message.inbox_id, identifier: image_identifiers)
                      .includes(image_attachment: :blob)
                      .index_by(&:identifier)

    Rails.logger.info "[AMB ListPicker] Batch loaded #{existing_images.size} existing images (avoiding N+1 queries)"

    # Performance Optimization: Process images in batches to control memory usage
    # and provide better progress tracking for large image sets
    batch_size = 10
    total_batches = (images.length.to_f / batch_size).ceil
    successful_count = 0
    failed_count = 0
    skipped_count = 0

    images.each_slice(batch_size).with_index do |batch, batch_index|
      Rails.logger.info "[AMB ListPicker] Processing batch #{batch_index + 1}/#{total_batches} (#{batch.length} images)"

      batch.each do |image_data|
        Rails.logger.info "[AMB ListPicker] Processing image: #{image_data['identifier']}, has data: #{image_data['data'].present?}"

        # Skip invalid images
        unless image_data['identifier'].present? && image_data['data'].present?
          Rails.logger.warn '[AMB ListPicker] Skipping image with missing identifier or data'
          skipped_count += 1
          next
        end

        # Use pre-loaded existing image (no database query here)
        existing_image = existing_images[image_data['identifier']]

        Rails.logger.info "[AMB ListPicker] Existing image found: #{existing_image.present?}, has attachment: #{existing_image&.image&.attached?}"

        # Skip if already saved with attachment
        if existing_image&.image&.attached?
          Rails.logger.info "[AMB ListPicker] Image #{image_data['identifier']} already exists, skipping"
          skipped_count += 1
          next
        end

        # Create or update the image record
        picker_image = existing_image || AppleListPickerImage.new(
          account_id: message.account_id,
          inbox_id: message.inbox_id,
          identifier: image_data['identifier']
        )

        picker_image.description = image_data['description']
        picker_image.original_name = image_data['originalName'] || image_data['identifier']

        # Decode base64 and attach to ActiveStorage
        begin
          # Validate base64 format before decoding
          unless %r{\A[A-Za-z0-9+/]*={0,2}\z}.match?(image_data['data'])
            Rails.logger.error "[AMB ListPicker] Invalid base64 format for image #{image_data['identifier']}"
            failed_count += 1
            next
          end

          decoded_data = Base64.strict_decode64(image_data['data'])

          # Validate decoded data size (prevent memory issues)
          max_size = 10.megabytes
          if decoded_data.bytesize > max_size
            Rails.logger.error "[AMB ListPicker] Image #{image_data['identifier']} exceeds max size (#{decoded_data.bytesize} bytes > #{max_size} bytes)"
            failed_count += 1
            next
          end

          # Determine filename and content type
          filename = picker_image.original_name || "#{image_data['identifier']}.jpg"
          content_type = determine_content_type(decoded_data, filename)

          # Attach to ActiveStorage
          picker_image.image.attach(
            io: StringIO.new(decoded_data),
            filename: filename,
            content_type: content_type
          )

          picker_image.save!
          successful_count += 1
          Rails.logger.info "[AMB ListPicker] Successfully saved image to ActiveStorage: #{image_data['identifier']}"
        rescue ArgumentError => e
          Rails.logger.error "[AMB ListPicker] Base64 decode failed for image #{image_data['identifier']}: #{e.message}"
          failed_count += 1
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "[AMB ListPicker] Validation failed for image #{image_data['identifier']}: #{e.message}"
          failed_count += 1
        rescue StandardError => e
          Rails.logger.error "[AMB ListPicker] Failed to save image #{image_data['identifier']}: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          failed_count += 1

          # Clear decoded data from memory after processing
        end
      end

      # Log batch completion with progress
      Rails.logger.info "[AMB ListPicker] Batch #{batch_index + 1}/#{total_batches} completed"
    end

    # Log final summary with statistics
    Rails.logger.info "[AMB ListPicker] Image processing complete: #{successful_count} successful, #{skipped_count} skipped, #{failed_count} failed out of #{images.length} total"
  end

  def determine_content_type(data, filename)
    # Try to detect from data
    return 'image/png' if data[0..3] == "\x89PNG"
    return 'image/jpeg' if data[0..1] == "\xFF\xD8"
    return 'image/gif' if data[0..2] == 'GIF'
    return 'image/webp' if data[8..11] == 'WEBP'

    # Fallback to filename extension
    ext = File.extname(filename).downcase
    case ext
    when '.png' then 'image/png'
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.gif' then 'image/gif'
    when '.webp' then 'image/webp'
    else 'image/jpeg' # default
    end
  end

  # Override parent to properly transform section/item keys
  def build_list_picker_data
    Rails.logger.info '[AMB ListPicker] 🚀 USING CHILD CLASS build_list_picker_data override'
    sections = content_attributes['sections'] || []

    Rails.logger.info "[AMB ListPicker] build_list_picker_data called with #{sections.length} sections"
    Rails.logger.info "[AMB ListPicker] First section items: #{sections.first&.dig('items')&.inspect}"

    # Transform sections to camelCase for Apple MSP
    transformed_sections = sections.map.with_index do |section, section_index|
      transformed_section = {
        'title' => section['title'],
        'multipleSelection' => section['multipleSelection'] || section['multiple_selection'] || false,
        'order' => section['order'] || section_index
      }

      # Transform items
      if section['items'].present?
        Rails.logger.info "[AMB ListPicker] Section '#{section['title']}' has #{section['items'].length} items"
        transformed_section['items'] = section['items'].map.with_index do |item, item_index|
          Rails.logger.info "[AMB ListPicker] Item #{item_index}: #{item.inspect}"

          transformed_item = {
            'identifier' => item['identifier'] || SecureRandom.uuid,
            'title' => item['title'],
            'subtitle' => item['subtitle'],
            'order' => item['order'] || item_index,
            'style' => item['style'] || 'icon'
          }

          # CRITICAL: Transform image_identifier to imageIdentifier
          if item['image_identifier'].present?
            transformed_item['imageIdentifier'] = item['image_identifier']
            Rails.logger.info "[AMB ListPicker] ✅ Item '#{item['title']}' has imageIdentifier: #{item['image_identifier']}"
          elsif item['imageIdentifier'].present?
            # Also check camelCase version
            transformed_item['imageIdentifier'] = item['imageIdentifier']
            Rails.logger.info "[AMB ListPicker] ✅ Item '#{item['title']}' has imageIdentifier (camelCase): #{item['imageIdentifier']}"
          else
            Rails.logger.info "[AMB ListPicker] ❌ Item '#{item['title']}' has NO image_identifier or imageIdentifier, keys: #{item.keys.inspect}"
          end

          Rails.logger.info "[AMB ListPicker] 🟢 Transformed item keys: #{transformed_item.keys.inspect}"
          transformed_item
        end
      else
        Rails.logger.info "[AMB ListPicker] Section '#{section['title']}' has NO items"
      end

      transformed_section
    end

    result = {
      sections: transformed_sections
    }
    Rails.logger.info "[AMB ListPicker] 🟢 CHILD CLASS FINAL RESULT first item keys: #{if result[:sections].first && result[:sections].first['items']&.first
                                                                                        result[:sections].first['items'].first.keys.inspect
                                                                                      end}"
    result
  end

  def build_list_picker_sections
    sections = content_attributes['sections'] || [default_section]

    # Debug: log raw sections data
    Rails.logger.info "[AMB ListPicker] Raw sections from content_attributes: #{sections.inspect}"

    sections.map.with_index do |section, index|
      {
        title: section['title'] || "Section #{index + 1}",
        multipleSelection: section['multipleSelection'] || section['multiple_selection'] || false,
        order: section['order'] || index,
        listPickerItem: build_list_picker_items(section['items'] || [])
      }
    end
  end

  def build_list_picker_items(items)
    items.map.with_index do |item, index|
      item_data = {
        identifier: item['identifier'] || SecureRandom.uuid,
        title: item['title'] || "Item #{index + 1}",
        subtitle: item['subtitle'],
        imageIdentifier: item['image_identifier'],
        order: item['order'] || index
      }
      # Debug log
      if item_data[:imageIdentifier].present?
        Rails.logger.info "[AMB ListPicker] Item '#{item_data[:title]}' has imageIdentifier: #{item_data[:imageIdentifier]}"
      end
      item_data
    end
  end

  def build_images_array
    images = content_attributes['images'] || []
    Rails.logger.info "[AMB ListPicker] Building images array with #{images.length} images"
    return [] if images.empty?

    # Transform images to Apple MSP format with base64 data
    images.map do |image|
      {
        identifier: image['identifier'],
        data: image['data'], # base64 encoded
        description: image['description']
      }.compact
    end
  end

  def build_received_message
    {
      title: content_attributes['received_title'] || 'Please select an option',
      subtitle: content_attributes['received_subtitle'],
      imageIdentifier: content_attributes['received_image_identifier'],
      style: content_attributes['received_style'] || 'small'
    }
  end

  def build_reply_message
    {
      title: content_attributes['reply_title'] || 'Selected: ${item.title}',
      subtitle: content_attributes['reply_subtitle'],
      imageIdentifier: content_attributes['reply_image_identifier'],
      style: content_attributes['reply_style'] || 'icon'
    }
  end

  def default_section
    {
      'title' => 'Options',
      'multiple_selection' => false,
      'items' => []
    }
  end

  def content_attributes
    @content_attributes ||= message.content_attributes || {}
  end
end
