class ContactDrop < BaseDrop
  def email
    @obj.try(:email)
  end

  def phone_number
    @obj.try(:phone_number)
  end
end
