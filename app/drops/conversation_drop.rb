class ConversationDrop < BaseDrop
  def display_id
    @obj.try(:display_id)
  end
end
