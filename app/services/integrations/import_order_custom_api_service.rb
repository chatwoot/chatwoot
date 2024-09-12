class Integrations::ImportOrderCustomApiService < Integrations::ImportOrderBaseService # rubocop:disable Metrics/ClassLength
  def import_orders
    response = fetch_orders
    orders = response['orders']

    orders.each { |order_data| process_order(order_data) }

    update_orders_last_update
  end

  private

  def process_order(order_data)
    ActiveRecord::Base.transaction do
      contact = create_or_update_contact(order_data)
      order = create_order(contact, order_data)
      create_order_items(order, order_data['lineItems'])
    end
  end

  def create_or_update_contact(order_data) # rubocop:disable Metrics/AbcSize
    account_data = order_data['account']
    formated_phone_number = format_phone_number_to_e164(account_data['phoneNumber'])

    contact_finded = find_first_contact(account_data, formated_phone_number)

    contact_corrupted = find_contact_corrupted(account_data, formated_phone_number, contact_finded[:contact_data],
                                               contact_finded[:type])

    # Atualiza o contato se ele já existe e não for corrompido
    return update_contact(contact_finded[:contact_data], order_data) if contact_corrupted.nil? && contact_finded

    unless contact_corrupted.nil?

      return create_corrupted_contact(account_data, order_data,
                                      find_corrupted_data(contact_corrupted[:contact_data], account_data), contact_finded[:contact_data])
    end

    Contact.create!(
      account_id: custom_api['account_id'],
      name: "#{account_data['firstName']} #{account_data['lastName']}",
      email: account_data['email'],
      phone_number: formated_phone_number,
      identifier: account_data['document'],
      custom_attributes: { :shipping_address => create_address_line(order_data['shippingAddress']) },
      additional_attributes: { :integration => custom_api['name'], :id_from_integration => account_data['id'] }
    )
  end

  def find_first_contact(account_data, formated_phone_number)
    # Verifica se o contato ja existe com base no id da integração
    contact = Contact.find_by("account_id = ? AND additional_attributes->>'id_from_integration' = ?", custom_api['account_id'],
                              account_data['id'].to_s)
    return { type: 'id_from_integration', contact_data: contact } unless contact.nil?

    # Verifica se já existe com base no email
    contact = Contact.find_by(account_id: custom_api['account_id'], email: account_data['email'], phone_number: formated_phone_number)
    return { :type => 'email', :contact_data => contact } unless contact.nil?

    { type: nil, contact_data: nil }
  end

  def find_contact_corrupted(account_data, formated_phone_number, contact_value, _type) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    # Verifica se já existe um contato com o phone_number
    phone_contact = Contact.where(account_id: custom_api['account_id'], phone_number: formated_phone_number)
    phone_contact = phone_contact.where.not(id: contact_value['id']) if contact_value.present?
    phone_contact = phone_contact.first

    # Verifica se já existe um contato com o identifier
    identifier_contact = Contact.where(account_id: custom_api['account_id'], identifier: account_data['document'])
    identifier_contact = identifier_contact.where.not(id: contact_value['id']) if contact_value.present?
    identifier_contact = identifier_contact.first

    # Se o mesmo contato tiver o phone_number e o identifier
    return { type: 'both', contact_data: [phone_contact.id] } if phone_contact && identifier_contact && phone_contact.id == identifier_contact.id

    # Se o phone_number e o identifier existirem em contatos diferentes, retorna conflito
    if phone_contact && identifier_contact && phone_contact.id != identifier_contact.id
      return { type: 'conflict', contact_data: [phone_contact.id, identifier_contact.id] }
    end

    # Se apenas o phone_number já estiver registrado
    return { type: 'phone', contact_data: [phone_contact.id] } if phone_contact

    # Se apenas o identifier já estiver registrado
    return { type: 'identifier', contact_data: [identifier_contact.id] } if identifier_contact

    nil
  end

  def create_order(contact, order_data) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    order = Order.find_or_initialize_by(order_key: order_data['id'], order_number: order_data['orderNumber'], contact: contact)
    checkout = order_data['checkout']
    order.update!(
      contact: contact,
      account_id: custom_api['account_id'],
      order_number: order_data['orderNumber'],
      order_key: order_data['id'],
      created_via: order_data['origin'],
      platform: custom_api['name'],
      status: map_status(order_data['fulfillmentStatus']),
      date_created: order_data['createdAt'],
      date_modified: order_data['updatedAt'],
      discount_total: order_data['totalDiscount'],
      shipping_total: order_data['totalShipping'],
      discount_coupon: handle_coupon(order_data['appliedDiscounts']),
      total: order_data['total'],
      prices_include_tax: true,
      payment_method: checkout['payment']['method'],
      payment_status: checkout['payment']['status'],
      transaction_id: order_data['invoiceId'],
      set_paid: false
    )
    order
  end

  def create_order_items(order, line_items)
    line_items.each do |item|
      order_item = OrderItem.find_or_initialize_by(order: order, product_id: item['id'], variation_id: item['variantId'])
      order_item.update!(
        order: order,
        name: item['title'],
        product_id: item['id'],
        variation_id: item['variantId'],
        quantity: item['quantity'],
        tax_class: item['tax_class'],
        subtotal: item['subtotal'],
        subtotal_tax: item['subtotal_tax'],
        total: item['total'],
        total_tax: item['total_tax'],
        sku: item['sku'],
        price: item['price']
      )
    end
  end

  def update_contact(contact, order_data)
    account_data = order_data['account']

    formated_phone_number = format_phone_number_to_e164(account_data['phoneNumber'])
    contact_attributes = {
      name: "#{account_data['firstName']} #{account_data['lastName']}",
      email: account_data['email'],
      phone_number: formated_phone_number,
      identifier: account_data['document'],
      custom_attributes: add_attributes(contact, { :shipping_address => create_address_line(order_data['shippingAddress']) }),
      additional_attributes: add_attributes(contact, { :integration => custom_api['name'], :id_from_integration => account_data['id'] })
    }

    contact.update!(contact_attributes)

    contact
  end

  def create_corrupted_contact(account_data, order_data, corrupted_values, contact_finded)
    contact_attributes = {
      account_id: custom_api['account_id'],
      name: "#{account_data['firstName']} #{account_data['lastName']}",
      custom_attributes: add_attributes(contact_finded, build_custom_attributes(order_data, corrupted_values)),
      additional_attributes: add_attributes(contact_finded, { :integration => custom_api['name'], :id_from_integration => account_data['id'] })
    }

    unless corrupted_values[:corrupted_type] == 'both' || corrupted_values[:corrupted_type] == 'conflict'

      contact_attributes[:identifier] = account_data['document'] unless corrupted_values[:corrupted_type] == 'identifier'

      contact_attributes[:phone_number] = format_phone_number_to_e164(account_data['phoneNumber']) unless corrupted_values[:corrupted_type] == 'phone'
    end

    if contact_finded
      contact_finded.update!(contact_attributes)
      return contact_finded
    end

    contact_attributes[:email] = account_data['email']

    Contact.create!(contact_attributes)
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

  def find_corrupted_data(contact_ids, account_data) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
    formatted_phone = format_phone_number_to_e164(account_data['phoneNumber'])
    contacts = Contact.where(id: contact_ids)
    if contact_ids.length > 1
      corrupted_value = []
      contacts.each do |contact|
        if contact.phone_number == formatted_phone
          corrupted_value << contact.phone_number
        elsif contact.identifier == account_data['document']
          corrupted_value << contact.identifier
        end
      end
      { corrupted_contact: contact_ids, corrupted_type: 'conflict', corrupted_value: corrupted_value }
    else
      contact = contacts.first
      if contact.phone_number == formatted_phone && contact.identifier == account_data['document']
        { corrupted_contact: [contact.id], corrupted_type: 'both', corrupted_value: [contact['phone_number'], contact['identifier']] }
      elsif contact.phone_number == formatted_phone
        { corrupted_contact: [contact.id], corrupted_type: 'phone', corrupted_value: [contact['phone_number']] }
      else
        { corrupted_contact: [contact.id], corrupted_type: 'identifier', corrupted_value: [contact['identifier']] }
      end
    end
  end

  def fetch_orders
    perform_request(endpoint: 'orders')
  end

  def handle_coupon(discounts)
    discount = discounts.find { |d| d['description'] != 'PIX' }
    discount ? discount['description'] : ''
  end

  def map_status(status)
    status_mapper = {
      'FULFILLED' => 'Finalizado',
      'SHIPPED' => 'Enviado',
      'IN_PROGRESS' => 'Em Produção',
      'PARTIALLY_FULFILLED' => 'Envio de fotos finalizado',
      'PENDING_PHOTOS' => 'Aguardando o envio de fotos',
      'PENDING_FULFILLMENT' => 'Aguardando atendimento',
      'CANCELED' => 'Cancelado'
    }.freeze

    status_mapper[status] || status
  end
end
