# CUSTOMIZAÇÃO_SYNAPSEOS: backfills the three contact custom attributes
# (ultima_revisao, carro_atual, propensao_troca) for every existing account so
# the "Dados do Sistema Legado" sidebar panel has definitions to render.
class BackfillSynapseosCustomAttributes < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    Account.find_each do |account|
      ::Synapseos::CustomAttributesSeeder.new(account).perform!
    rescue StandardError => e
      Rails.logger.error("[Synapseos] Backfill failed for account ##{account.id}: #{e.message}")
    end
  end

  def down
    keys = ::Synapseos::CustomAttributesSeeder::CONTACT_ATTRIBUTES.pluck(:key)
    CustomAttributeDefinition.where(attribute_model: 'contact_attribute', attribute_key: keys).destroy_all
  end
end
