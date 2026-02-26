class BaseDrop < Liquid::Drop
  def initialize(obj)
    @obj = obj
  end

  def id
    @obj.try(:id)
  end

  def name
    @obj.try(:name)
  end
end
