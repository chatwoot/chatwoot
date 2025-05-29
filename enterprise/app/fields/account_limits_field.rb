require 'administrate/field/base'

class AccountLimitsField < Administrate::Field::Base
  def to_s
    data.present? ? data.to_json : { agents: nil, inboxes: nil, aiagent_responses: nil, aiagent_documents: nil }.to_json
  end
end
