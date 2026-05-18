require 'rails_helper'

RSpec.describe ChatwootGlpiIntegration::Connection, type: :model do
  let(:account) { create(:account) }

  it 'is valid with required fields' do
    expect(build(:glpi_connection, account: account)).to be_valid
  end

  it 'requires https/http base_url' do
    expect(build(:glpi_connection, account: account, base_url: 'glpi.com')).not_to be_valid
  end

  it 'has a token endpoint derived from base_url' do
    c = build(:glpi_connection, account: account, base_url: 'https://glpi.example.com/')
    expect(c.token_endpoint).to eq('https://glpi.example.com/api.php/token')
  end

  it 'encrypts client_secret at rest' do
    c = create(:glpi_connection, account: account, client_secret: 'topsecret')
    raw = ActiveRecord::Base.connection.execute(
      "select client_secret from chatwoot_glpi_connections where id = #{c.id}"
    ).first['client_secret']
    expect(raw).not_to include('topsecret')
  end
end
