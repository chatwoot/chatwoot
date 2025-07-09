class TypingIndicatorTestService
  attr_reader :conversation

  def initialize(conversation:)
    @conversation = conversation
  end

  def test_typing_indicators
    results = {}
    
    # Test Facebook typing if it's a Facebook channel
    if conversation.inbox.channel_type == 'Channel::FacebookPage'
      results[:facebook] = test_facebook_typing
    end

    # Test Instagram typing if it's an Instagram channel
    if conversation.inbox.channel_type == 'Channel::Instagram'
      results[:instagram] = test_instagram_typing
    end

    results
  end

  private

  def test_facebook_typing
    return { error: 'Contact or source_id missing' } if contact_source_id.blank?

    typing_service = Facebook::TypingIndicatorService.new(conversation.inbox.channel, contact_source_id)

    test_results = {}

    # Test mark_seen
    Rails.logger.info "Testing Facebook mark_seen for conversation #{conversation.id}"
    test_results[:mark_seen] = typing_service.mark_seen
    sleep(1)

    # Test typing_on
    Rails.logger.info "Testing Facebook typing_on for conversation #{conversation.id}"
    test_results[:typing_on] = typing_service.enable
    sleep(3) # Keep typing indicator for 3 seconds

    # Test typing_off
    Rails.logger.info "Testing Facebook typing_off for conversation #{conversation.id}"
    test_results[:typing_off] = typing_service.disable

    test_results
  rescue => e
    Rails.logger.error "Error testing Facebook typing: #{e.message}"
    { error: e.message }
  end

  def test_instagram_typing
    return { error: 'Contact or source_id missing' } if contact_source_id.blank?

    # Instagram sử dụng cùng service với Facebook
    typing_service = Facebook::TypingIndicatorService.new(conversation.inbox.channel, contact_source_id)

    test_results = {}

    # Test mark_seen
    Rails.logger.info "Testing Instagram mark_seen for conversation #{conversation.id}"
    test_results[:mark_seen] = typing_service.mark_seen
    sleep(1)

    # Test typing_on
    Rails.logger.info "Testing Instagram typing_on for conversation #{conversation.id}"
    test_results[:typing_on] = typing_service.enable
    sleep(3) # Keep typing indicator for 3 seconds

    # Test typing_off
    Rails.logger.info "Testing Instagram typing_off for conversation #{conversation.id}"
    test_results[:typing_off] = typing_service.disable

    test_results
  rescue => e
    Rails.logger.error "Error testing Instagram typing: #{e.message}"
    { error: e.message }
  end

  def contact_source_id
    @contact_source_id ||= conversation.contact&.get_source_id(conversation.inbox.id)
  end
end
