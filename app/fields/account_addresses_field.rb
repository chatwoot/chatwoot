require 'administrate/field/base'

class AccountAddressesField < Administrate::Field::Base
  def to_s
    addresses.map { |addr| "#{addr.street} #{addr.exterior_number}, #{addr.city}" }.join('; ')
  end

  def addresses
    data || []
  end

  def nested_form_key
    :account_addresses_attributes
  end
end
