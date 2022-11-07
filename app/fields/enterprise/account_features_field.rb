require 'administrate/field/base'

class Enterprise::AccountFeaturesField < Administrate::Field::Base
  def to_s
    data
  end
end
