class Avatar::AvatarFromUrlJob < ApplicationJob
  queue_as :low
  discard_on ActiveJob::DeserializationError

  # Thêm retry cho job
  retry_on Down::NotFound, Down::Error, wait: 30.seconds, attempts: 3

  def perform(avatarable, avatar_url)
    # Kiểm tra xem avatarable có tồn tại không
    avatarable_class = avatarable.class.name
    avatarable_id = avatarable.id

    # Nếu không thể tìm thấy đối tượng, ghi log và thoát
    unless avatarable_exists?(avatarable)
      Rails.logger.warn("#{avatarable_class} ##{avatarable_id} không còn tồn tại, bỏ qua việc tải avatar")
      return
    end

    return unless avatarable.respond_to?(:avatar)
    return if avatar_url.blank?

    Rails.logger.info("Downloading avatar from URL: #{avatar_url} for #{avatarable_class} ##{avatarable_id}")

    begin
      # Xử lý URL Facebook Graph API đặc biệt
      if avatar_url.include?('graph.facebook.com') && avatar_url.include?('/picture')
        # Kiểm tra nếu URL chưa được xử lý (vẫn chứa redirect=false)
        if avatar_url.include?('redirect=false')
          begin
            response = HTTParty.get(avatar_url)
            if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['data'].present?
              # Lấy URL trực tiếp từ JSON response
              data = response.parsed_response['data']
              if data['url'].present?
                avatar_url = data['url']
                Rails.logger.info("Extracted direct URL from Facebook JSON response: #{avatar_url}")
              end
            end
          rescue => e
            Rails.logger.error("Error processing Facebook JSON response: #{e.message}")
            # Nếu xử lý JSON thất bại, sử dụng URL đã tối ưu
            avatar_url = optimize_facebook_avatar_url(avatar_url)
          end
        end
      end

      avatar_file = Down.download(
        avatar_url,
        max_size: 15 * 1024 * 1024
      )

      if valid_image?(avatar_file)
        # Kiểm tra lại một lần nữa trước khi attach
        if avatarable_exists?(avatarable)
          avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                                   content_type: avatar_file.content_type)
          Rails.logger.info("Successfully attached avatar for #{avatarable_class} ##{avatarable_id}")
        else
          Rails.logger.warn("#{avatarable_class} ##{avatarable_id} không còn tồn tại khi đang attach avatar")
        end
      else
        Rails.logger.warn("Invalid image file from URL: #{avatar_url}")
      end
    rescue Down::NotFound => e
      Rails.logger.error("Avatar not found at URL #{avatar_url}: #{e.message}")
      try_fallback_avatar(avatarable, avatar_url) if avatarable_exists?(avatarable)
    rescue Down::Error => e
      Rails.logger.error("Error downloading avatar from URL #{avatar_url}: #{e.message}")
      try_fallback_avatar(avatarable, avatar_url) if avatarable_exists?(avatarable)
    rescue StandardError => e
      Rails.logger.error("Unexpected error processing avatar from URL #{avatar_url}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end

  private

  # Kiểm tra xem avatarable có còn tồn tại trong database không
  def avatarable_exists?(avatarable)
    begin
      # Sử dụng find thay vì exists? để đảm bảo reload đối tượng từ database
      avatarable.class.find(avatarable.id).present?
    rescue ActiveRecord::RecordNotFound
      false
    end
  end

  # Tối ưu URL avatar Facebook theo tài liệu mới nhất
  def optimize_facebook_avatar_url(url)
    # Thêm tham số redirect=false để nhận JSON thay vì redirect
    # Thêm width và height cụ thể
    # Thêm cache buster để tránh cache
    base_url = url.split('?').first
    params = {}

    # Parse các tham số hiện tại
    if url.include?('?')
      query_string = url.split('?').last
      query_string.split('&').each do |param|
        key, value = param.split('=')
        params[key] = value if key.present? && value.present?
      end
    end

    # Thêm các tham số mới
    params['width'] = '200'
    params['height'] = '200'
    params['redirect'] = 'false'
    params['type'] ||= 'normal'
    params['cb'] = Time.now.to_i.to_s

    # Tạo URL mới
    new_url = base_url + '?' + params.map { |k, v| "#{k}=#{v}" }.join('&')
    Rails.logger.info("Optimized Facebook avatar URL: #{new_url}")
    new_url
  end

  def valid_image?(file)
    return false if file.original_filename.blank?

    # Kiểm tra nếu file là hình ảnh hợp lệ
    begin
      content_type = file.content_type.to_s.downcase
      return content_type.start_with?('image/')
    rescue StandardError => e
      Rails.logger.error("Error validating image: #{e.message}")
      false
    end
  end

  def try_fallback_avatar(avatarable, original_url)
    # Nếu URL là từ Facebook Graph API, thử lại với tham số khác
    if original_url.include?('graph.facebook.com') && original_url.include?('/picture')
      # Thử nhiều loại tham số khác nhau
      fallback_urls = []

      # Tạo các URL fallback theo tài liệu mới nhất của Facebook
      base_url = original_url.split('?').first

      # Lấy access_token từ URL gốc nếu có
      access_token = nil
      if original_url.include?('access_token=')
        access_token_match = original_url.match(/access_token=([^&]+)/)
        access_token = access_token_match[1] if access_token_match
      end

      # Thêm access_token vào URL fallback nếu có
      token_param = access_token.present? ? "&access_token=#{access_token}" : ""

      # Thử với type=normal, redirect=true (không sử dụng JSON response)
      fallback_urls << "#{base_url}?type=normal&width=100&height=100#{token_param}&cb=#{Time.now.to_i}"

      # Thử với type=square, redirect=true
      fallback_urls << "#{base_url}?type=square&width=100&height=100#{token_param}&cb=#{Time.now.to_i + 1}"

      # Thử với type=large, redirect=true
      fallback_urls << "#{base_url}?type=large#{token_param}&cb=#{Time.now.to_i + 2}"

      # Thử với chỉ width=200, height=200
      fallback_urls << "#{base_url}?width=200&height=200#{token_param}&cb=#{Time.now.to_i + 3}"

      # Thử với URL không có tham số
      fallback_urls << "#{base_url}?cb=#{Time.now.to_i + 4}#{token_param}"

      # Thử từng URL fallback
      fallback_urls.each do |fallback_url|
        Rails.logger.info("Trying fallback Facebook avatar URL: #{fallback_url}")

        begin
          avatar_file = Down.download(
            fallback_url,
            max_size: 15 * 1024 * 1024
          )

          if valid_image?(avatar_file) && avatarable_exists?(avatarable)
            avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                                     content_type: avatar_file.content_type)
            Rails.logger.info("Successfully attached fallback avatar for #{avatarable.class.name} ##{avatarable.id}")
            return true # Thoát khi đã tải thành công
          end
        rescue => e
          Rails.logger.error("Failed to download fallback avatar from #{fallback_url}: #{e.message}")
        end
      end
    end

    false # Trả về false nếu không thể tải bất kỳ avatar nào
  end
end
