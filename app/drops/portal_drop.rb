class PortalDrop < BaseDrop
  def name
    @obj.try(:name)
  end

  def custom_domain
    @obj.try(:custom_domain)
  end

  def slug
    @obj.try(:slug)
  end
end
