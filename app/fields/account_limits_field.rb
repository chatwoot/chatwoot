class AccountLimitsField < Administrate::Field::Base
  def limit_keys
    %i[agents inboxes captain_responses captain_documents emails]
  end

  def limits_data
    data.is_a?(Hash) ? data : {}
  end

  def value_for(key)
    limits_data[key.to_s] || limits_data[key.to_sym]
  end
end
