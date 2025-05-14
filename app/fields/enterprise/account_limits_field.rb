require 'administrate/field/base'

class Enterprise::AccountLimitsField < Administrate::Field::Base
  def to_s
    if data.present?
      # Transform database keys to display format
      transformed_data = {
        'Agent Limit' => data['agents'],
        'Inbox Limit' => data['inboxes']
      }
      transformed_data.to_json
    else
      { 'Agent Limit' => nil, 'Inbox Limit' => nil }.to_json
    end
  end
end
