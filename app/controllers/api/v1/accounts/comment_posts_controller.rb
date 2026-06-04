# frozen_string_literal: true

class Api::V1::Accounts::CommentPostsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    sort = params[:sort_by]&.to_s == 'post_date' ? :ordered_by_post_date : :ordered_by_latest_comment
    @comment_posts = Current.account.comment_posts
                            .for_inbox(params[:inbox_id])
                            .for_platform(params[:platform])
                            .public_send(sort)
                            .page(params[:page] || 1)
                            .per(20)

    render json: {
      data: {
        meta: { total_count: @comment_posts.total_count, page: @comment_posts.current_page },
        payload: @comment_posts.map { |post| serialize_post(post) }
      }
    }
  end

  def show
    @comment_post = Current.account.comment_posts.find(params[:id])
    conversations = @comment_post.conversations
                                 .includes(:contact, :inbox, :messages)
                                 .order(last_activity_at: :desc)
                                 .limit(50)

    render json: {
      data: {
        post: serialize_post(@comment_post),
        conversations: conversations.map { |c| serialize_conversation(c) }
      }
    }
  end

  # Called by omni-ai when a comment is processed — creates/updates post record
  def upsert
    post = Current.account.comment_posts.find_or_initialize_by(post_id: params[:post_id])
    post.assign_attributes(upsert_params)
    post.last_comment_at = Time.current
    post.conversations_count = (post.conversations_count || 0) + 1 if post.new_record? || params[:increment_count]

    # Auto-resolve inbox_id if not provided (e.g. after inbox was deleted and re-created)
    if post.inbox_id.blank? && post.platform.present?
      resolved = post.resolved_inbox
      post.inbox_id = resolved.id if resolved
    end

    # Fetch metadata from Graph API server-side if not provided and post_text is blank
    fetch_post_metadata_from_graph(post) if post.post_text.blank? && post.post_id.present?

    post.save!

    render json: { data: serialize_post(post) }, status: post.previously_new_record? ? :created : :ok
  end

  private

  def check_authorization
    return if action_name == 'upsert'

    authorize(Current.account) if defined?(authorize)
  end

  def upsert_params
    params.permit(
      :inbox_id, :platform, :post_id, :page_id,
      :post_text, :post_media_url, :post_media_type,
      :post_permalink, :post_created_at
    )
  end

  def fetch_post_metadata_from_graph(post)
    inbox = post.resolved_inbox
    return unless inbox

    token = resolve_channel_token(inbox)
    return unless token.present?

    fields = if post.platform == 'instagram'
               'caption,media_url,media_type,permalink,timestamp'
             else
               'message,full_picture,permalink_url,created_time,type'
             end

    response = HTTParty.get(
      "https://graph.facebook.com/v22.0/#{post.post_id}",
      query: { fields: fields, access_token: token },
      timeout: 5
    )
    return unless response.success?

    data = response.parsed_response
    if post.platform == 'instagram'
      post.post_text = data['caption'] if data['caption'].present?
      post.post_media_url = data['media_url'] if data['media_url'].present?
      post.post_media_type = data['media_type']&.downcase if data['media_type'].present?
      post.post_permalink = data['permalink'] if data['permalink'].present?
      post.post_created_at = data['timestamp'] if data['timestamp'].present?
    else
      post.post_text = data['message'] if data['message'].present?
      post.post_media_url = data['full_picture'] if data['full_picture'].present?
      post.post_media_type = data['type'] == 'video' ? 'video' : (data['full_picture'].present? ? 'image' : 'text')
      post.post_permalink = data['permalink_url'] if data['permalink_url'].present?
      post.post_created_at = data['created_time'] if data['created_time'].present?
    end
  rescue StandardError => e
    Rails.logger.warn("[CommentPosts] Graph API metadata fetch failed: #{e.message}")
  end

  def resolve_channel_token(inbox)
    channel = inbox.channel
    return nil unless channel

    if channel.respond_to?(:page_access_token)
      channel.page_access_token
    elsif channel.respond_to?(:access_token)
      channel.access_token
    end
  end

  def serialize_post(post)
    {
      id: post.id,
      platform: post.platform,
      post_id: post.post_id,
      page_id: post.page_id,
      post_text: post.post_text&.truncate(200),
      post_media_url: post.post_media_url,
      post_media_type: post.post_media_type,
      post_permalink: post.post_permalink,
      post_created_at: post.post_created_at&.iso8601,
      conversations_count: post.conversations_count,
      last_comment_at: post.last_comment_at&.iso8601,
      inbox_id: post.inbox_id,
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601
    }
  end

  def serialize_conversation(conv)
    {
      id: conv.id,
      status: conv.status,
      contact: {
        id: conv.contact&.id,
        name: conv.contact&.name,
        thumbnail: conv.contact&.avatar_url
      },
      additional_attributes: conv.additional_attributes,
      last_activity_at: conv.last_activity_at&.to_i,
      created_at: conv.created_at.iso8601,
      messages_count: conv.messages.count,
      last_message: conv.messages.order(created_at: :desc).first&.then { |m|
        { content: m.content&.truncate(100), created_at: m.created_at.iso8601, message_type: m.message_type }
      }
    }
  end
end
