class Integrations::CustomApi::CreateOrUpdateContactService
  include ::IntegrationContactHelper

  def initialize(order_data, custom_api, account_data)
    @data = order_data
    @custom_api = custom_api
    @account_data = (order_data && order_data['account']) || account_data
    @formated_phone_number = format_phone_number_to_e164(@account_data['phoneNumber'])
  end

  def perform
    create_or_update_contact
  end

  def create_or_update_contact
    contact_corrupted = find_contact_corrupted(first_contact)
    # Atualiza o contato se ele já existe e não for corrompido
    return update_contact(first_contact[:contact_data]) if contact_corrupted.nil? && first_contact[:contact_data]

    return create_corrupted_contact(find_corrupted_data(contact_corrupted[:contact_data])) unless contact_corrupted.nil?

    create_contact
  end

  def create_contact
    Contact.create!(
      account_id: @custom_api['account_id'],
      name: "#{@account_data['firstName']} #{@account_data['lastName']}",
      email: @account_data['email'],
      phone_number: @formated_phone_number,
      identifier: @account_data['document'],
      custom_attributes: { :shipping_address => create_address_line(@data['shippingAddress']) },
      additional_attributes: { :integration => @custom_api['name'], :id_from_integration => @account_data['id'] }
    )
  end

  def update_contact(contact)
    contact_attributes = {
      name: "#{@account_data['firstName']} #{@account_data['lastName']}",
      email: @account_data['email'],
      phone_number: @formated_phone_number,
      identifier: @account_data['document'],
      custom_attributes: contact_custom_attributes(contact),
      additional_attributes: add_attributes(contact, { :integration => @custom_api['name'], :id_from_integration => @account_data['id'] })
    }
    contact.update!(contact_attributes)
    contact
  end

  private

  def create_corrupted_contact(corrupted_values)
    contact_finded = find_contact_by_integration_id

    contact_attributes = {
      account_id: @custom_api['account_id'],
      name: "#{@account_data['firstName']} #{@account_data['lastName']}",
      custom_attributes: add_attributes(contact_finded, corrupted_attributes(corrupted_values)),
      additional_attributes: add_attributes(contact_finded, { :integration => @custom_api['name'], :id_from_integration => @account_data['id'] })
    }

    unless corrupted_values[:corrupted_type] == 'both' || corrupted_values[:corrupted_type] == 'conflict'

      contact_attributes[:identifier] = @account_data['document'] unless corrupted_values[:corrupted_type] == 'identifier'

      unless corrupted_values[:corrupted_type] == 'phone'
        contact_attributes[:phone_number] =
          format_phone_number_to_e164(@account_data['phoneNumber'])
      end
    end

    if contact_finded

      contact_finded.update!(contact_attributes)
      return contact_finded
    end

    contact_attributes[:email] = @account_data['email'] if first_contact[:contact_data][:email] != @account_data['email']

    Contact.create!(contact_attributes)
  end

  def first_contact
    # Verifica se o contato ja existe com base no id da integração
    contact = Contact.find_by("account_id = ? AND additional_attributes->>'id_from_integration' = ? AND active = ?", @custom_api['account_id'],
                              @account_data['id'].to_s, true)
    return { type: 'id_from_integration', contact_data: contact } unless contact.nil?

    # Verifica se já existe com base no email
    contact = Contact.find_by(account_id: @custom_api['account_id'], email: @account_data['email'], active: true)
    return { :type => 'email', :contact_data => contact } unless contact.nil?

    # Verifica se já existe com base no phone
    contact = Contact.find_by(account_id: @custom_api['account_id'], phone_number: @formated_phone_number, active: true)
    return { :type => 'phone', :contact_data => contact } unless contact.nil?

    { type: nil, contact_data: nil }
  end

  def find_contact_corrupted(contact_value) # rubocop:disable Metrics/CyclomaticComplexity
    # Verifica se já existe um contato com o phone_number
    phone_contact = Contact.where(account_id: @custom_api['account_id'], phone_number: @formated_phone_number, active: true)
    phone_contact = if contact_value[:type] == 'phone' || contact_value[:type] == 'id_from_integration'
                      phone_contact.find_by("additional_attributes->>'id_from_integration' != ?",
                                            @account_data['id'].to_s)
                    else
                      phone_contact.first
                    end

    # Verifica se já existe um contato com o identifier
    identifier_contact = Contact.where(account_id: @custom_api['account_id'], identifier: @account_data['document'], active: true)
    identifier_contact = identifier_contact.find_by(
      "additional_attributes->>'id_from_integration' != ?", @account_data['id'].to_s
    )

    # Se o mesmo contato tiver o phone_number e o identifier
    return { type: 'both', contact_data: [phone_contact.id] } if phone_contact && identifier_contact && phone_contact.id == identifier_contact.id

    # Se o phone_number e o identifier existirem em contatos diferentes, retorna conflito
    return { type: 'conflict', contact_data: [phone_contact.id, identifier_contact.id] } if phone_contact && identifier_contact

    # Se apenas o phone_number já estiver registrado
    return { type: 'phone', contact_data: [phone_contact.id] } if phone_contact

    # Se apenas o identifier já estiver registrado
    return { type: 'identifier', contact_data: [identifier_contact.id] } if identifier_contact

    nil
  end

  def find_corrupted_data(contact_ids) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    contacts = Contact.where(id: contact_ids)
    if contact_ids.length > 1
      corrupted_value = []
      contacts.each do |contact|
        if contact.phone_number == @formated_phone_number
          corrupted_value << contact.phone_number
        elsif contact.identifier == @account_data['document']
          corrupted_value << contact.identifier
        end
      end
      { contact_corrupted: contact_ids, corrupted_type: 'conflict', corrupted_value: corrupted_value }
    else
      contact = contacts.first
      if contact.phone_number == @formated_phone_number && contact.identifier == @account_data['document']
        { contact_corrupted: [contact.id], corrupted_type: 'both', corrupted_value: [contact['phone_number'], contact['identifier']] }
      elsif contact.phone_number == @formated_phone_number
        { contact_corrupted: [contact.id], corrupted_type: 'phone', corrupted_value: [contact['phone_number']] }
      else
        { contact_corrupted: [contact.id], corrupted_type: 'identifier', corrupted_value: [contact['identifier']] }
      end
    end
  end

  def contact_custom_attributes(contact)
    return add_attributes(contact, { shipping_address: create_address_line(@data['shippingAddress']) }) if @data && @data['shippingAddress']

    contact.custom_attributes
  end

  def corrupted_attributes(corrupted_values)
    @data && @data['shippingAddress'] ? corrupted_values.merge(shipping_address: create_address_line(@data['shippingAddress'])) : corrupted_values
  end

  def find_contact_by_integration_id
    Contact.find_by("account_id = ? AND additional_attributes->>'id_from_integration' = ? AND active = ?", @custom_api['account_id'],
                    @account_data['id'].to_s, true)
  end
end
