# The embedded WhatsApp connector keeps its store (pairings, Signal keys, pending history)
# in this schema of Chatwoot's own database, reached with `search_path=whatsapp_connector`
# (docker/entrypoints/helpers/whatsapp_connector.rb). Creating it here rather than when the
# connector starts means the worker never needs a privilege the rest of the app does not.
# A role that cannot create schemas gets a warning instead of a stopped upgrade, for this
# schema only: config/initializers/whatsapp_connector_schema.rb.
class CreateWhatsappConnectorSchema < ActiveRecord::Migration[7.2]
  def up
    create_schema 'whatsapp_connector', if_not_exists: true
  end

  def down
    drop_schema 'whatsapp_connector', if_exists: true
  end
end
