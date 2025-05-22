class Facebook::FetchProfileService
  pattr_initialize [:user_id!, :page_access_token!]

  def perform
    begin
      # Thử lấy thông tin người dùng từ Facebook Graph API
      k = Koala::Facebook::API.new(page_access_token)
      result = k.get_object(user_id, fields: 'first_name,last_name,profile_pic,name,id') || {}

      # Ghi log thông tin người dùng để debug
      Rails.logger.info("Facebook user data for user #{user_id}: #{result.inspect}")

      # Luôn sử dụng URL trực tiếp từ Graph API thay vì dùng profile_pic từ API response
      # Điều này giúp tránh các vấn đề với URL tạm thời hoặc URL không truy cập được
      avatar_url = get_direct_avatar_url(user_id, page_access_token)

      # URL đã được xử lý trong get_direct_avatar_url để lấy URL trực tiếp

      result['profile_pic'] = avatar_url
      Rails.logger.info("Using direct Graph API URL for avatar: #{result['profile_pic']}")

      return result
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.warn("Facebook authentication error for user #{user_id}: #{e.message}")
      Rails.logger.error e
      return { error: 'authentication_error', message: e.message }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.warn("Facebook client error for user #{user_id}: #{e.message}")

      # Thử lấy avatar trực tiếp từ Graph API ngay cả khi có lỗi
      avatar_url = get_direct_avatar_url(user_id, page_access_token)
      Rails.logger.info("Using direct Graph API URL for avatar after error: #{avatar_url}")

      return {
        'profile_pic' => avatar_url,
        'first_name' => 'Facebook',
        'last_name' => 'User',
        error: 'client_error',
        message: e.message
      }
    rescue StandardError => e
      Rails.logger.error("Facebook unexpected error for user #{user_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # Thử lấy avatar trực tiếp từ Graph API ngay cả khi có lỗi
      avatar_url = get_direct_avatar_url(user_id, page_access_token)

      return {
        'profile_pic' => avatar_url,
        'first_name' => 'Facebook',
        'last_name' => 'User',
        error: 'unexpected_error',
        message: e.message
      }
    end
  end

  # Tạo URL trực tiếp để lấy avatar từ Facebook Graph API theo tài liệu mới nhất
  def get_direct_avatar_url(user_id, access_token)
    # Thêm tham số redirect=false để nhận JSON thay vì redirect
    # Thêm width và height cụ thể
    # Thêm cache buster để tránh cache
    cache_buster = Time.now.to_i
    url = "https://graph.facebook.com/#{user_id}/picture?type=large&width=200&height=200&redirect=false&access_token=#{access_token}&cb=#{cache_buster}"

    # Lấy URL trực tiếp từ JSON response ngay tại đây
    begin
      response = HTTParty.get(url)
      if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['data'].present?
        data = response.parsed_response['data']
        if data['url'].present?
          Rails.logger.info("Extracted direct URL from Facebook JSON response for user #{user_id}")
          return data['url']
        end
      end
    rescue => e
      Rails.logger.error("Error processing Facebook JSON response: #{e.message}")
    end

    # Fallback to original URL if JSON processing fails
    url
  end
end
