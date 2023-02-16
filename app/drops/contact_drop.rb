class ContactDrop < BaseDrop
  def email
    @obj.try(:email)
  end

  def phone_number
    @obj.try(:phone_number)
  end

  def first_name
    @obj.try(:name).try(:split).try(:first)
  end

  def last_name
    @obj.try(:name).try(:split).try(:last) if @obj.try(:name).try(:split).try(:size) > 1
  end
end
