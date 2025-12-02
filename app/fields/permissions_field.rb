require 'administrate/field/base'

class PermissionsField < Administrate::Field::Base
  def to_s
    data.join(', ')
  end

  def available_permissions
    CustomRole::PERMISSIONS
  end
end

