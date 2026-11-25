# The schema the embedded WhatsApp connector keeps its store in (whatsapp_connector) is
# created like any other part of the database: by its migration, and by db/schema.rb on a
# fresh database, which Rails dumps as `create_schema "whatsapp_connector"`. Both go
# through here.
#
# A database role that may create tables but not schemas would otherwise have its whole
# install or upgrade stopped by an optional channel. For this one schema, that refusal is a
# warning instead: everything else in Chatwoot works, and the connector's start says the
# schema is missing and the statement that creates it. Any other error, and any other
# schema, still raises.
module WhatsappConnectorSchema
  NAME = 'whatsapp_connector'.freeze

  # In a savepoint, so a refusal inside a migration's transaction does not abort it. Always
  # IF NOT EXISTS for this schema: db/schema.rb dumps it without, and a schema load over an
  # already migrated database would otherwise stop at it.
  def create_schema(schema_name, **options)
    options = options.merge(if_not_exists: true) if schema_name.to_s == NAME
    transaction(requires_new: true) { super(schema_name, **options) }
  rescue ActiveRecord::StatementInvalid => e
    raise unless schema_name.to_s == NAME && e.cause.is_a?(PG::InsufficientPrivilege)
    # Postgres checks the privilege before IF NOT EXISTS: a schema already there is no failure.
    return if schema_exists?(NAME)

    Rails.logger.warn(
      "Could not create schema #{NAME} (#{e.cause.message.strip}). The WhatsApp (native) connector will not " \
      "start until it exists: CREATE SCHEMA #{NAME} AUTHORIZATION <the database user Chatwoot connects as>"
    )
  end
end

ActiveSupport.on_load(:active_record_postgresqladapter) { prepend WhatsappConnectorSchema }
