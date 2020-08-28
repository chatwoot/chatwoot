class BaseDrop < Liquid::Drop
  def initialize(obj)
    @obj = obj
    super
  end

  def id
    @obj.try(:id)
  end

  def name
    @obj.try(:name)
  end
end
