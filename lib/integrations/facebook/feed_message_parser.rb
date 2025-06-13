# frozen_string_literal: true

class Integrations::Facebook::FeedMessageParser
  def initialize(response_json)
    @response = JSON.parse(response_json)
    @event_data = @response['change']['value']
  end

  def sender_id
    @event_data.dig('from', 'id')
  end

  def sender_name
    @event_data.dig('from', 'name')
  end

  def page_id
    post_id.split('_').first
  end

  def post_id
    @event_data['post_id']
  end

  def comment_id
    @event_data['comment_id']
  end

  def post_url
    @event_data.dig('post', 'permalink_url')
  end

  def item_type
    @event_data['item']
  end

  def verb
    @event_data['verb']
  end

  def content
    @event_data['message']
  end

  def attachment
    if @event_data['photo'].present?
      { 'type': 'image', payload: { url: @event_data['photo'] } }.deep_stringify_keys
    elsif @event_data['video'].present?
      { type: 'video', payload: { url: @event_data['video'] } }.deep_stringify_keys
    end
  end
end
