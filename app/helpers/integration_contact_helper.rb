module IntegrationContactHelper
  def format_phone_number_to_e164(phone_number)
    digits = phone_number.gsub(/\D/, '')

    if digits.start_with?('55')
      "+#{digits}"
    else
      "+55#{digits}"
    end
  end

  def build_custom_attributes(order_data, corrupted_data = nil)
    attributes = {
      shipping_address: create_address_line(order_data['shippingAddress'])
    }

    if corrupted_data
      attributes.merge!(
        contact_corrupted: corrupted_data[:corrupted_contact],
        corrupted_value: corrupted_data[:corrupted_value],
        corrupted_type: corrupted_data[:corrupted_type]
      )
    end

    attributes
  end

  def create_address_line(address)
    address_line = "#{address['street']}, #{address['number']}, #{address['neighborhood']}" \
                   ", #{address['city']}-#{address['state']}, #{address['zipCode']}"
    address_line += ", #{address['complement']}" unless address['complement'].to_s.strip.empty?
    address_line
  end

  def add_attributes(contact, hash_attribue)
    (contact&.custom_attributes || {}).deep_merge(hash_attribue.stringify_keys)
  end
end
