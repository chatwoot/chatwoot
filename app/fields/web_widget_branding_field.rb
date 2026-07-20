require 'administrate/field/base'

class WebWidgetBrandingField < Administrate::Field::Base
  def to_s
    data
  end
end
