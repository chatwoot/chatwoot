require 'administrate/field/base'

class StatusField < Administrate::Field::Base
  def to_s
    data.to_s.capitalize
  end

  def active?
    data.to_s == 'active'
  end

  def selectable_options
    [%w[Active active], %w[Suspended suspended]]
  end
end
