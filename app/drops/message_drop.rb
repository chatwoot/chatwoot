class MessageDrop < BaseDrop
  def sender_display_name
    @obj.sender.try(:display_name)
  end

  def text_content
    content = @obj.try(:content)
    # This will remove /[@user](mention://user/3/user)/ from the content
    text = content.sub(%r{\[@.+\]\(mention://(user|team)/(\d+)/(.+)\) }, '') if content.present?
    text
  end
end
