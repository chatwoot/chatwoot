require 'administrate/field/base'

class Enterprise::AccountLimitsField < Administrate::Field::Base
  def to_s
    data.present? ? data.to_json : { agents: nil, inboxes: nil }.to_json
  end
end
