require 'administrate/field/base'

class AvatarField < Administrate::Field::Base
  def avatar_url
    return data.presence if data.presence

    resource.is_a?(User) ? '/assets/administrate/user/avatar.png' : '/assets/administrate/bot/avatar.png'
  end
end
