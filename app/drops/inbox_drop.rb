class InboxDrop < BaseDrop
  def name
    @obj.try(:name)
  end

  def business_name
    @obj.try(:sanitized_business_name)
  end

  def avatar_url
    @obj.try(:avatar_url)
  end

  def email
    return unless @obj.try(:email?)

    @obj.try(:email_address).presence || @obj.try(:channel).try(:email)
  end
end
