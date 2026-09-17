require_relative '../../../lib/wootql'

# Model doubles let parser/resolver/compiler tests run without booting Chatwoot
# or connecting to a database. Each relation supplies a trusted account scope.
RSpec.shared_context 'with a WootQL catalog' do
  let(:now) { Time.utc(2026, 9, 17, 12) }
  let(:field_types) do
    {
      'messages' => { 'id' => :integer, 'conversation_id' => :integer, 'content' => :text, 'private' => :boolean,
                      'created_at' => :datetime, 'updated_at' => :datetime, 'sender_type' => :string },
      'conversations' => { 'id' => :integer, 'contact_id' => :integer, 'status' => :integer, 'last_activity_at' => :datetime },
      'contacts' => { 'id' => :integer, 'name' => :string }
    }
  end
  let(:catalog) do
    {
      'messages' => { fields: field_types.fetch('messages').keys,
                      relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
      'conversations' => { fields: field_types.fetch('conversations').keys, query_fields: { 'labels' => :string_list },
                           relations: { 'contact' => ['contacts', 'contact_id', :one], 'messages' => ['messages', 'conversation_id', :many] } },
      'contacts' => { fields: field_types.fetch('contacts').keys, relations: {} }
    }
  end
  let(:schema) { Wootql::Schema.new }
  let(:data) { double('authorized data access') }
  let(:connection) { double('database connection', adapter_name: 'PostgreSQL') }

  before do
    stub_const('Captain::Apropos::ResourceCatalog', double('Chatwoot resource catalog', entries: catalog))
    allow(Captain::Apropos::ResourceCatalog).to receive(:fetch) { |resource| catalog.fetch(resource) }
    allow(Wootql::Schema).to receive(:new).and_return(schema)
    allow(schema).to receive(:expression).and_call_original
    allow(schema).to receive(:expression).with('conversations', 'labels').and_return('ARRAY[]::text[]')
    allow(data).to receive(:scope) { |resource| raise Wootql::Error, "Unknown resource: #{resource}" }
    field_types.each do |resource, types|
      enums = resource == 'conversations' ? { 'status' => { 'open' => 0, 'resolved' => 1 } } : {}
      model = class_double(ActiveRecord::Base, quoted_table_name: "\"#{resource}\"", defined_enums: enums)
      allow(model).to receive(:type_for_attribute) { |field| double(type: types.fetch(field)) }
      relation = double("scoped #{resource}", klass: model)
      allow(relation).to receive(:reorder).with(nil).and_return(relation)
      allow(relation).to receive(:reselect) do |projection|
        double(to_sql: "SELECT #{projection} FROM \"#{resource}\" WHERE \"#{resource}\".\"account_id\" = 7")
      end
      allow(data).to receive(:scope).with(resource).and_return(relation)
    end
    allow(connection).to receive(:quote_column_name) { |name| "\"#{name.gsub('"', '""')}\"" }
  end
end
