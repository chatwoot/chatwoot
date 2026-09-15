class Crm::Cpfcnpj::Mappers::ContactMapper
  def self.map(document, type, response)
    new(document, type, response).map
  end

  # Writes the enrichment payload under additional_attributes['cpfcnpj'] and
  # maintains a few well known fields. A field is written, or cleared when the
  # new result does not provide it, only while it is blank or still holds the
  # value the previous enrichment wrote, so a document change refreshes it and
  # anything typed by a person is kept. The caller persists the contact.
  def self.apply(contact, mapped)
    contact.additional_attributes ||= {}
    previous = contact.additional_attributes['cpfcnpj'].to_h
    contact.additional_attributes['cpfcnpj'] = mapped
    contact.name = mapped['name'] if mapped['name'].present? && replaceable?(contact.name, previous['name'])
    apply_company_attributes(contact, mapped, previous)
    contact
  end

  def self.apply_company_attributes(contact, mapped, previous)
    company = mapped['type'] == 'cnpj'
    previous_company = previous['type'] == 'cnpj'
    sync_additional_attribute(contact, 'company_name', company ? mapped['name'] : nil, previous_company ? previous['name'] : nil)
    sync_additional_attribute(contact, 'city', company ? mapped['city'] : nil, previous_company ? previous['city'] : nil)
    sync_additional_attribute(contact, 'country_code', 'BR', 'BR')
  end

  def self.sync_additional_attribute(contact, key, value, previous_value)
    return unless replaceable?(contact.additional_attributes[key], previous_value)

    if value.present?
      contact.additional_attributes[key] = value
    else
      contact.additional_attributes.delete(key)
    end
  end

  def self.replaceable?(current, previous_value)
    current.blank? || (previous_value.present? && current == previous_value)
  end

  def initialize(document, type, response)
    @document = document
    @type = type
    @response = response.to_h
  end

  def map
    type == :cnpj ? company_attributes : person_attributes
  end

  private

  attr_reader :document, :type, :response

  # For a CPF only the minimum data is kept (LGPD data minimization).
  def person_attributes
    {
      'document' => document,
      'type' => 'cpf',
      'name' => response['nome'],
      'status' => response['situacao'],
      'looked_up_at' => looked_up_at,
      'package' => response['pacoteUsado']
    }
  end

  def company_attributes
    company_identity.merge(company_address).merge(company_registration)
  end

  def company_identity
    {
      'document' => document,
      'type' => 'cnpj',
      'name' => response['razao'],
      'trade_name' => response['fantasia'],
      'status' => nested('situacao', 'nome'),
      'status_date' => nested('situacao', 'data'),
      'looked_up_at' => looked_up_at,
      'package' => response['pacoteUsado']
    }
  end

  def company_address
    {
      'state' => nested('matrizEndereco', 'uf'),
      'city' => nested('matrizEndereco', 'cidade'),
      'zip_code' => nested('matrizEndereco', 'cep')
    }
  end

  def company_registration
    {
      'opened_at' => response['inicioAtividade'],
      'company_size' => nested('porte', 'descricao'),
      'legal_nature' => nested('naturezaJuridica', 'descricao'),
      'cnae_code' => nested('cnae', 'fiscal'),
      'cnae_description' => nested('cnae', 'descricao'),
      'share_capital' => response['capitalSocial'],
      'partners_count' => partners.size,
      'partners' => partners.map { |partner| partner_entry(partner) },
      'simples_nacional' => optante?('optante'),
      'mei' => optante?('mei')
    }
  end

  def partners
    response['socios'].is_a?(Array) ? response['socios'] : []
  end

  # Only name and role are surfaced; the partner document stays out of the ficha.
  def partner_entry(partner)
    { 'name' => partner['nome'], 'role' => partner_role(partner) }
  end

  def partner_role(partner)
    qualification = partner['qualificacao_socio']
    return qualification['descricao'] if qualification.is_a?(Hash)

    qualification
  end

  # Lighter packages omit the Simples Nacional section entirely; only an explicit
  # answer from the provider becomes a boolean.
  def optante?(key)
    value = nested('simplesNacional', key)
    return nil if value.nil?

    value == 'Sim'
  end

  # Lighter packages omit whole sections and some providers return a scalar
  # where the full profile has a hash; either way the field is simply absent.
  def nested(*keys)
    keys.reduce(response) { |node, key| node.is_a?(Hash) ? node[key] : nil }
  end

  def looked_up_at
    Time.current.iso8601
  end
end
