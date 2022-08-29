require 'administrate/field/base'

class AvatarField < Administrate::Field::Base
  def avatar_url
    data.presence || "#{ENV.fetch('FRONTEND_URL')}/assets/administrate/avatar.png"
  end
end
