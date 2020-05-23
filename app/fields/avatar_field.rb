require 'administrate/field/base'

class AvatarField < Administrate::Field::Base
  def avatar_url
    data.presence || '/admin/avatar.png'
  end
end
