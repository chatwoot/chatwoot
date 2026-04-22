# CUSTOMIZAÇÃO_SYNAPSEOS: seeds the contact custom attributes used by the
# Syonet/NBS integrations to populate the "Dados do Sistema Legado" sidebar panel.
module Synapseos
  class CustomAttributesSeeder
    CONTACT_ATTRIBUTES = [
      { key: 'ultima_revisao', display_name: 'Última Revisão', display_type: 'date' },
      { key: 'carro_atual', display_name: 'Carro Atual', display_type: 'text' },
      { key: 'propensao_troca', display_name: 'Propensão de Troca (%)', display_type: 'number' }
    ].freeze

    def initialize(account)
      @account = account
    end

    def perform!
      CONTACT_ATTRIBUTES.each { |attr| upsert_contact_attribute(attr) }
    end

    private

    def upsert_contact_attribute(attr)
      record = CustomAttributeDefinition.find_or_initialize_by(
        account: @account,
        attribute_key: attr[:key],
        attribute_model: 'contact_attribute'
      )
      return if record.persisted?

      record.attribute_display_name = attr[:display_name]
      record.attribute_display_type = attr[:display_type]
      record.save!
    end
  end
end
