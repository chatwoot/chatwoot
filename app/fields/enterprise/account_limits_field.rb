require 'administrate/field/base'

class Enterprise::AccountLimitsField < Administrate::Field::Base
  def to_s
    data.present? ? data.to_json : { 'Agent Limit' => nil, 'Inbox Limit' => nil }.to_json
    # captain_responses: nil, captain_documents: nil
  end
end
