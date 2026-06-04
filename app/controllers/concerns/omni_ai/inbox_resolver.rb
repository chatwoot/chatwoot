# frozen_string_literal: true

# Shared concern for OmniAi controllers to resolve an inbox even when the
# provided inbox_id is stale (e.g. the inbox was deleted and re-created).
#
# Fallback strategy:
#   1. Inbox.find_by(id: inbox_id)                — direct lookup
#   2. Extract page_id from post_id param          — format: {page_id}_{story_id}
#   3. Channel::FacebookPage.find_by(page_id: ...) — find channel by Meta page id
#   4. Return the channel's inbox

module OmniAi
  module InboxResolver
    extend ActiveSupport::Concern

    private

    # Resolve inbox from params, falling back to channel lookup when the ID is stale.
    def resolve_inbox
      inbox = Inbox.find_by(id: params[:inbox_id]) if params[:inbox_id].present?
      return inbox if inbox

      # Try to find channel by page_id extracted from post_id ({page_id}_{story_id})
      page_id = extract_page_id_from_params
      if page_id.present?
        channel = Channel::FacebookPage.find_by(page_id: page_id)
        return channel.inbox if channel&.inbox
      end

      # Fallback: look up page_id from CommentPost records (useful when only comment_id is available)
      comment_id = params[:comment_id].to_s.strip
      if comment_id.present?
        # comment_id format: {post_story_id}_{comment_id} — the post_story_id links to a CommentPost
        story_id = comment_id.split('_', 2).first
        cp = CommentPost.where('post_id LIKE ?', "%#{story_id}%").first if story_id.present?
        if cp&.page_id.present?
          channel = Channel::FacebookPage.find_by(page_id: cp.page_id)
          return channel.inbox if channel&.inbox
        end
      end

      # Last resort: find by platform if there's exactly one matching channel
      platform = params[:platform].to_s.downcase
      if platform == 'facebook'
        channels = Channel::FacebookPage.where.not(page_id: [nil, ''])
        return channels.first.inbox if channels.count == 1 && channels.first.inbox
      elsif platform == 'instagram'
        channels = Channel::FacebookPage.where.not(instagram_id: [nil, ''])
        return channels.first.inbox if channels.count == 1 && channels.first.inbox
      end

      nil
    end

    def extract_page_id_from_params
      post_id = params[:post_id].to_s.strip
      return post_id.split('_', 2).first if post_id.include?('_')

      nil
    end
  end
end
