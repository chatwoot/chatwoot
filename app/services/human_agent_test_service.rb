class HumanAgentTestService
  attr_reader :conversation

  def initialize(conversation:)
    @conversation = conversation
  end

  def test_human_agent_configuration
    results = {}
    
    return { error: 'Conversation not found' } if conversation.blank?
    return { error: 'Not a Facebook/Instagram channel' } unless facebook_or_instagram_channel?

    Rails.logger.info "HumanAgentTestService: Testing human agent configuration for conversation #{conversation.id}"

    # Test 1: Kiểm tra cấu hình global
    results[:global_config] = test_global_config

    # Test 2: Test gửi tin nhắn với human_agent tag
    results[:message_test] = test_human_agent_message

    # Test 3: Kiểm tra permissions Facebook App
    results[:permissions] = test_facebook_permissions

    Rails.logger.info "HumanAgentTestService: Completed human agent test for conversation #{conversation.id}"
    results
  end

  private

  def facebook_or_instagram_channel?
    conversation.inbox.channel_type.in?(['Channel::FacebookPage', 'Channel::Instagram'])
  end

  def test_global_config
    Rails.logger.info "HumanAgentTestService: Testing global configuration"
    
    results = {}
    
    # Test Facebook Messenger human_agent config
    fb_config = GlobalConfig.get('ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT')
    fb_enabled = fb_config['ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT']
    results[:facebook_messenger] = {
      enabled: fb_enabled == true || fb_enabled == 'true',
      raw_value: fb_enabled,
      config_exists: fb_config.present?
    }

    # Test Instagram human_agent config
    ig_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
    ig_enabled = ig_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
    results[:instagram] = {
      enabled: ig_enabled == true || ig_enabled == 'true',
      raw_value: ig_enabled,
      config_exists: ig_config.present?
    }

    # Kiểm tra channel hiện tại
    current_channel = conversation.inbox.channel_type
    results[:current_channel] = current_channel
    
    if current_channel == 'Channel::FacebookPage'
      results[:current_channel_enabled] = results[:facebook_messenger][:enabled]
    elsif current_channel == 'Channel::Instagram'
      results[:current_channel_enabled] = results[:instagram][:enabled]
    end

    results
  rescue => e
    Rails.logger.error "HumanAgentTestService: Error testing global config: #{e.message}"
    { error: e.message }
  end

  def test_human_agent_message
    Rails.logger.info "HumanAgentTestService: Testing human agent message sending"
    
    begin
      # Tạo một tin nhắn test
      test_message = conversation.messages.create!(
        account: conversation.account,
        inbox: conversation.inbox,
        message_type: 'outgoing',
        content: 'Test human agent message - This should bypass 24h window',
        sender: conversation.account.users.first || create_test_user
      )

      # Kiểm tra messaging params sẽ được sử dụng
      service = create_send_service(test_message)
      messaging_params = get_messaging_params(service)

      # Xóa tin nhắn test
      test_message.destroy

      {
        success: true,
        messaging_type: messaging_params[:messaging_type],
        tag: messaging_params[:tag],
        human_agent_detected: messaging_params[:tag] == 'HUMAN_AGENT',
        timestamp: Time.current
      }
    rescue => e
      Rails.logger.error "HumanAgentTestService: Error testing human agent message: #{e.message}"
      { success: false, error: e.message, timestamp: Time.current }
    end
  end

  def test_facebook_permissions
    Rails.logger.info "HumanAgentTestService: Testing Facebook app permissions"
    
    return { error: 'Not a Facebook channel' } unless conversation.inbox.channel_type == 'Channel::FacebookPage'

    begin
      channel = conversation.inbox.channel
      access_token = channel.page_access_token

      # Test API call để kiểm tra permissions
      response = HTTParty.get(
        'https://graph.facebook.com/v22.0/me/permissions',
        query: { access_token: access_token }
      )

      if response.success?
        permissions = response.parsed_response['data'] || []
        human_agent_permission = permissions.find { |p| p['permission'] == 'pages_messaging' }
        
        {
          success: true,
          has_pages_messaging: human_agent_permission.present?,
          permission_status: human_agent_permission&.dig('status'),
          all_permissions: permissions.map { |p| "#{p['permission']}: #{p['status']}" },
          timestamp: Time.current
        }
      else
        {
          success: false,
          error: "API Error: #{response.code} - #{response.message}",
          timestamp: Time.current
        }
      end
    rescue => e
      Rails.logger.error "HumanAgentTestService: Error testing Facebook permissions: #{e.message}"
      { success: false, error: e.message, timestamp: Time.current }
    end
  end

  def create_send_service(message)
    case conversation.inbox.channel_type
    when 'Channel::FacebookPage'
      Facebook::SendOnFacebookService.new(message: message)
    when 'Channel::Instagram'
      if conversation.inbox.channel.is_a?(Channel::FacebookPage)
        Instagram::Messenger::SendOnInstagramService.new(message: message)
      else
        Instagram::SendOnInstagramService.new(message: message)
      end
    end
  end

  def get_messaging_params(service)
    if service.respond_to?(:determine_messaging_params, true)
      service.send(:determine_messaging_params)
    elsif service.respond_to?(:merge_human_agent_tag, true)
      # Test với params mẫu
      test_params = { messaging_type: 'RESPONSE', tag: nil }
      service.send(:merge_human_agent_tag, test_params)
    else
      { messaging_type: 'UNKNOWN', tag: 'UNKNOWN' }
    end
  end

  def create_test_user
    conversation.account.users.create!(
      name: 'Test User',
      email: "test-#{SecureRandom.hex(4)}@example.com",
      password: SecureRandom.hex(8),
      confirmed_at: Time.current
    )
  end
end
