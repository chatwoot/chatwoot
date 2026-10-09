class Instagram::CommentText < Instagram::WebhooksBaseService
  attr_reader :comment

  def initialize(comment, channel)
    @comment = comment.with_indifferent_access
    super(channel)
  end

  def perform
    inbox_channel(@channel.instagram_id)
    return if @inbox.blank?

    if @inbox.channel.reauthorization_required?
      Rails.logger.info("Skipping comment; reauthorization required for inbox #{@inbox.id}")
      return
    end

    # Ignore comments authored by the connected account itself (our own replies / echoes)
    # to avoid feedback loops.
    return if own_comment?

    find_or_create_contact(commenter_user)
    return if @contact_inbox.blank?

    Messages::Instagram::CommentBuilder.new(@comment, @inbox).perform
  end

  private

  def own_comment?
    commenter_id == @channel.instagram_id.to_s
  end

  def commenter_id
    @comment.dig(:from, :id).to_s
  end

  # Build the user hash expected by WebhooksBaseService#find_or_create_contact.
  # The comments webhook already provides the commenter's username, so a Graph API
  # profile fetch is not required for the base flow.
  def commenter_user
    {
      'id' => commenter_id,
      'name' => @comment.dig(:from, :username).presence || "IG User #{commenter_id}",
      'username' => @comment.dig(:from, :username)
    }.with_indifferent_access
  end
end
