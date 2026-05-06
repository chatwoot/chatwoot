module ContactPointParams
  CONTACT_POINT_PARAMS = [:email, :phone_number, :email_addresses, :additional_emails, :phone_numbers, :additional_phones].freeze
  CONTACT_POINT_ARRAY_PARAMS = [:email_addresses, :additional_emails, :phone_numbers, :additional_phones].freeze

  private

  def contact_update_params
    permitted_params.except(:custom_attributes, :avatar_url, *CONTACT_POINT_PARAMS)
                    .merge({ custom_attributes: contact_custom_attributes })
                    .merge({ additional_attributes: contact_additional_attributes })
  end

  def contact_create_params
    permitted_params.except(:avatar_url, *CONTACT_POINT_PARAMS)
  end

  def contact_point_params
    point_params = permitted_params.slice(*CONTACT_POINT_PARAMS)
    CONTACT_POINT_ARRAY_PARAMS.each do |key|
      point_params[key] = params[key] if params[key] == '[]'
    end
    point_params
  end

  def replace_contact_points!
    Contacts::ReplaceContactPoints.new(contact: @contact, params: contact_point_params).perform
  end
end
