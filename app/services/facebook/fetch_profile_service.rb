class Facebook::FetchProfileService
  pattr_initialize [:user_id!, :page_access_token!]

  def perform
    begin
      # Thử lấy thông tin người dùng từ Facebook Graph API
      k = Koala::Facebook::API.new(page_access_token)
      result = k.get_object(user_id, fields: 'first_name,last_name,profile_pic,name,id') || {}
      
      # Ghi log thông tin người dùng để debug
      Rails.logger.info("Facebook user data for user #{user_id}: #{result.inspect}")
      
      # Nếu không có profile_pic, thử lấy trực tiếp từ Graph API
      if result['profile_pic'].blank?
        result['profile_pic'] = "https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}"
        Rails.logger.info("Using direct Graph API URL for avatar: #{result['profile_pic']}")
      end
      
      return result
    rescue Koala::Facebook::AuthenticationError => e
      Rails.logger.warn("Facebook authentication error for user #{user_id}: #{e.message}")
      Rails.logger.error e
      return { error: 'authentication_error', message: e.message }
    rescue Koala::Facebook::ClientError => e
      Rails.logger.warn("Facebook client error for user #{user_id}: #{e.message}")
      
      # Thử lấy avatar trực tiếp từ Graph API ngay cả khi có lỗi
      avatar_url = "https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}"
      Rails.logger.info("Using direct Graph API URL for avatar after error: #{avatar_url}")
      
      return {
        'profile_pic' => avatar_url,
        error: 'client_error',
        message: e.message
      }
    rescue StandardError => e
      Rails.logger.error("Facebook unexpected error for user #{user_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      # Thử lấy avatar trực tiếp từ Graph API ngay cả khi có lỗi
      avatar_url = "https://graph.facebook.com/#{user_id}/picture?type=large&access_token=#{page_access_token}"
      
      return {
        'profile_pic' => avatar_url,
        error: 'unexpected_error',
        message: e.message
      }
    end
  end
end
