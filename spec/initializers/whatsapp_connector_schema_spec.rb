require 'rails_helper'

# config/initializers/whatsapp_connector_schema.rb: the connector's schema is the one part of
# the database whose refusal must not stop an install or an upgrade.
RSpec.describe WhatsappConnectorSchema do
  let(:connection) { ActiveRecord::Base.connection }

  def refuse_schema_creation
    allow(connection).to receive(:execute).and_wrap_original do |original, sql, *args, **kwargs|
      next original.call(sql, *args, **kwargs) unless sql.start_with?('CREATE SCHEMA')

      begin
        raise PG::InsufficientPrivilege, 'ERROR:  permission denied for database chatwoot'
      rescue PG::InsufficientPrivilege
        raise ActiveRecord::StatementInvalid, 'PG::InsufficientPrivilege: permission denied for database chatwoot'
      end
    end
  end

  it 'creates the schema, and again without complaint when it is there' do
    connection.create_schema 'whatsapp_connector', if_not_exists: true
    connection.create_schema 'whatsapp_connector', if_not_exists: true

    expect(connection.schema_exists?('whatsapp_connector')).to be(true)
  end

  it 'loads db/schema.rb over a database that already has it' do
    connection.create_schema 'whatsapp_connector', if_not_exists: true

    expect { connection.create_schema 'whatsapp_connector' }.not_to raise_error
  end

  it 'stays quiet when the role may not create it but it is already there' do
    connection.create_schema 'whatsapp_connector', if_not_exists: true
    refuse_schema_creation
    allow(Rails.logger).to receive(:warn)

    connection.create_schema 'whatsapp_connector'

    expect(Rails.logger).not_to have_received(:warn)
  end

  it 'warns instead of failing when the role may not create it, and the transaction goes on' do
    connection.drop_schema 'whatsapp_connector', if_exists: true
    refuse_schema_creation
    allow(Rails.logger).to receive(:warn)

    connection.transaction do
      connection.create_schema 'whatsapp_connector'
      expect(connection.select_value('SELECT 1')).to eq(1)
    end

    expect(Rails.logger).to have_received(:warn).with(/Could not create schema whatsapp_connector .*CREATE SCHEMA whatsapp_connector AUTHORIZATION/)
  end

  it 'still fails for any other schema' do
    refuse_schema_creation

    expect { connection.create_schema 'something_else' }.to raise_error(ActiveRecord::StatementInvalid)
  end
end
