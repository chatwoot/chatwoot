require 'administrate/field/base'

class AvatarField < Administrate::Field::Base
  def avatar_url
    data.presence&.gsub('?d=404', '?d=mp')
  end
end
