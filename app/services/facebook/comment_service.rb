class Facebook::CommentService
  attr_reader :channel, :comment_id, :content
  
  def initialize(channel:, comment_id:, content:)
    @channel = channel
    @comment_id = comment_id
    @content = content
  end
  
  def reply
    begin
      graph = Koala::Facebook::API.new(channel.page_access_token)
      response = graph.put_comment(comment_id, content)
      
      if response
        Rails.logger.info "Successfully replied to Facebook comment: #{comment_id}"
        return {
          success: true,
          data: {
            comment_id: response['id'],
            created_time: response['created_time']
          }
        }
      else
        Rails.logger.warn "Failed to post comment to Facebook: #{comment_id}"
        return {
          success: false,
          error: 'Failed to post comment'
        }
      end
    rescue => e
      Rails.logger.error "Error replying to Facebook comment: #{e.message}"
      return {
        success: false,
        error: e.message
      }
    end
  end
end
