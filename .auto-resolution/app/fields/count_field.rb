require 'administrate/field/base'

class CountField < Administrate::Field::Base
  def to_s
    data.count
  end
end
